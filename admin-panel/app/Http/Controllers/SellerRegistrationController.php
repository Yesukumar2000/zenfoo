<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Seller;
use App\Models\Admin;
use App\Models\Role;
use App\Models\Category;
use App\Models\CategoryGroupStore;
use App\Models\SubCategoryGroup;
use App\Models\CategoryGroup;
use App\Models\Store;

use App\Models\SellerCommission;
use App\Notifications\SellerRegistrationNotification;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use App\Helpers\CommonHelper;
use App\Services\MediaUploadService;

class SellerRegistrationController extends Controller
{
    public function getSellerRegistrationData(Request $request)
    {
        try {
            $admin = auth()->guard('api')->user();

            if (!$admin) {
                return CommonHelper::responseError("Invalid token or unauthorized access.");
            }

            $seller = Seller::where('admin_id', $admin->id)->first();
            $store_data = Store::where('id', (int) $seller->store_id)->first();

            if (!$seller) {
                return CommonHelper::responseError("Seller profile not found.");
            }

            $storeImages = [];
            if (!empty($seller->store_images)) {
                $storeImages = json_decode($seller->store_images, true);
            }

            // Resolve the vendor-GST + commission applicable to this
            // seller from the store's category flags. Same precedence as
            // SellerOrderSettlementService::resolveVendorGstPercent /
            // resolveVendorCommissionPercent so the value the vendor
            // sees matches what they will be settled at.
            $vendorCategory = null;
            if ($store_data) {
                if (!empty($store_data->is_meat)) {
                    $vendorCategory = 'Chicken & Meat';
                } elseif (!empty($store_data->is_food)) {
                    $vendorCategory = 'Food';
                } elseif (!empty($store_data->is_super_mart)) {
                    $vendorCategory = 'Super Mart';
                } elseif (!empty($store_data->is_vegetable)) {
                    $vendorCategory = 'Vegetables & Fruits';
                }
            }
            $vendorGstCategory = $vendorCategory;
            $vendorCommissionCategory = $vendorCategory;
            $vendorGstPercent = $this->resolveVendorGstPercentForStore($seller->store_id);
            $vendorCommissionPercent = $this->resolveVendorCommissionPercentForStore($seller->store_id);

            $data = [
                "seller" => [
                    "id" => $seller->id,
                    "admin_id" => $admin->id,
                    "name" => $seller->name,
                    "email" => $seller->email,
                    "store_name" => $seller->store_name,
                    "store_description" => $seller->store_description,
                    "store_location" => $seller->store_location,
                    "store_city" => $seller->store_city,
                    "tax_name" => $seller->tax_name,
                    "tax_number" => $seller->tax_number,
                    "pan_number" => $seller->pan_number,
                    "fssai_number" => $seller->fssai_number,
                    "category_name" => $seller->category_name,
                    "aadhar_number" => $seller->aadhar_number,
                    "city_id" => $seller->city_id,
                    "commission" => $seller->commission,
                    "lat_long" => $seller->lat_long,
                    "store_id" => (string) $seller->store_id,
                    "store_type_name" => $store_data->name ?? null,
                    'shop_status'=> $seller->shop_status ?? 0,

                    "managed_by_admin" => $store_data->managed_by_admin ?? 0,

                    "is_sweet_house" => isset($seller->store_id) && $seller->store_id == 15 ? 1 : 0,


                    "categories_ids" => $seller->categories,
                    "store_url" => $seller->store_url,
                    "is_approved" => $seller->status,
                    'remark' => $seller->remark,

                    "logo_url" => $seller->logo,
                    "pan_img_url" => $seller->pan_img,
                    "fssai_img_url" => $seller->fssai_img,

                    "store_images" => $storeImages,

                    "national_id_card" => $seller->national_identity_card,

                    "address_proof" => $seller->address_proof,

                    // Document verification statuses
                    "pan_status" => $seller->pan_status ?? 0,
                    "fssai_status" => $seller->fssai_status ?? 0,
                    "aadhar_status" => $seller->aadhar_status ?? 0,
                    "agreement_status" => $seller->agreement_status ?? 0,
                    "agreement_pdf_url" => $seller->agreement_pdf_url,

                    // Applicable vendor GST + commission (dynamic, driven by store category flags + admin settings)
                    "vendor_gst_percent" => $vendorGstPercent,
                    "vendor_gst_category" => $vendorGstCategory,
                    "vendor_commission_percent" => $vendorCommissionPercent,
                    "vendor_commission_category" => $vendorCommissionCategory,
                ]
            ];

            return CommonHelper::responseSuccessWithData("Data fetched successfully", $data);

        } catch (\Exception $e) {
            Log::error("Seller Get Data Error:", [$e->getMessage()]);
            return CommonHelper::responseError("Something went wrong!");
        }
    }




    /**
     * POST Seller Registration
     */
    public function sellerRegister(Request $request)
    {
        $requestData = $request->all();

        $validator = Validator::make($requestData, [
            'name' => 'required',
            'email' => 'email|required',
            'password' => 'min:6|required_with:confirm_password|same:confirm_password',
            'categories_ids' => 'nullable',
            'store_name' => 'required',
            'store_id' => 'required|integer',
            'other_store_ids' => 'nullable|array',
            'other_store_ids.*' => 'nullable|integer',
            'store_url' => 'nullable|url',
            'city_id' => 'nullable',
            'pan_number' => 'nullable',
            'commission' => 'nullable',
            'national_id_card' => 'nullable|mimes:jpeg,jpg,png,gif,pdf',
            'address_proof' => 'nullable|mimes:jpeg,jpg,png,gif,pdf',
            'store_logo' => 'nullable|mimes:jpeg,jpg,png,gif,pdf',
            'store_description' => 'required',

            'lat_long' => 'required',
            'store_location' => 'required',
            'store_city' => 'required',
            'tax_name' => 'required',
            'tax_number' => 'required',
            'pan_img' => 'nullable|mimes:jpeg,jpg,png,gif,pdf',
            'fssai_img' => 'nullable|mimes:jpeg,jpg,png,gif,pdf',
            'store_images' => 'nullable|array',
            'store_images.*' => 'nullable|mimes:jpeg,jpg,png,gif,pdf',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        DB::beginTransaction();
        try {

            $adminUser = auth()->guard('api')->user();

            if (!$adminUser) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Admin authentication required.',
                    'data' => null
                ], 401);
            }

            $seller = Seller::where('admin_id', $adminUser->id)->first();

            if (!$seller) {
                $seller = new Seller();
            }

            Admin::where('id', $adminUser->id)->update([
                'username' => $request->name,
                'email' => $request->email,
                'password' => bcrypt($request->password),
                'created_by' => 0,
            ]);

            $seller->admin_id = $adminUser->id;
            $seller->name = $request->name;
            $seller->store_id = $request->store_id;
            $seller->other_store_ids = $request->other_store_ids ?? null;
            $seller->slug = $request->store_name;
            $seller->store_name = $request->store_name;
            $seller->email = $request->email;
            $seller->status = Seller::$statusRegistered;

            $seller->store_location = $request->store_location;
            $seller->store_city = $request->store_city;
            $seller->tax_name = $request->tax_name;
            $seller->tax_number = $request->tax_number;
            $seller->lat_long = $request->lat_long;

            $seller->store_url = $request->store_url;

            $seller->categories = $request->categories_ids ?? null;
            $seller->pan_number = $request->pan_number;
            $seller->fssai_number = $request->fssai_number ?? null;
            $seller->aadhar_number = $request->aadhar_number ?? null;
            $seller->category_name = $request->category_name ?? null;


            $seller->city_id = $request->city_id;
            $seller->store_description = $request->store_description;
            $seller->commission = $request->commission ?? 20;

            // Snapshot the admin-configured vendor GST + commission for
            // this seller's store category. The settlement service still
            // resolves the live rate from settings for ongoing payouts;
            // these columns are the historical record of what applied at
            // registration.
            if (\Schema::hasColumn('sellers', 'vendor_gst_percent')) {
                $seller->vendor_gst_percent = $this->resolveVendorGstPercentForStore($request->store_id);
            }
            if (\Schema::hasColumn('sellers', 'vendor_commission_percent')) {
                $seller->vendor_commission_percent = $this->resolveVendorCommissionPercentForStore($request->store_id);
            }



            // Upload files...
            if ($request->hasFile('store_logo')) {
                $seller->logo = MediaUploadService::uploadWithFullUrl($request->file('store_logo'), 'sellers');
            }

            if ($request->hasFile('pan_img')) {
                $seller->pan_img = MediaUploadService::uploadWithFullUrl($request->file('pan_img'), 'sellers');
            }

            if ($request->hasFile('fssai_img')) {
                $seller->fssai_img = MediaUploadService::uploadWithFullUrl($request->file('fssai_img'), 'sellers');
            }

            $imgs = [];
            if ($request->hasFile('store_images')) {
                foreach ($request->file('store_images') as $file) {
                    $imgs[] = MediaUploadService::uploadWithFullUrl($file, 'sellers');
                }
            }
            $seller->store_images = json_encode($imgs);

            if ($request->hasFile('national_id_card')) {
                $seller->national_identity_card = MediaUploadService::uploadWithFullUrl($request->file('national_id_card'), 'sellers');
            }

            if ($request->hasFile('address_proof')) {
                $seller->address_proof = MediaUploadService::uploadWithFullUrl($request->file('address_proof'), 'sellers');
            }

            $seller->save();

            // Save commissions
            // $categories = explode(',', $request->categories_ids);
            // foreach ($categories as $cat) {
            //     $sc = new SellerCommission();
            //     $sc->seller_id = $seller->id;
            //     $sc->category_id = $cat;
            //     $sc->save();
            // }

            DB::commit();

            // Send notification to seller about successful registration
            try {
                $adminUser->notify(new SellerRegistrationNotification($seller->id, 'seller_registration'));
            } catch (\Exception $e) {
                Log::error("Seller Registration Notification Error:", [$e->getMessage()]);
            }

            return CommonHelper::responseSuccess("Seller Registration Successful!");


        } catch (\Exception $e) {
            DB::rollBack();
            Log::error("Seller Register Error:", [$e->getMessage()]);
            return CommonHelper::responseError("Something went wrong!");
        }
    }



    /**
     * POST Seller Registration
     */
    public function sellerRegisterFromAdmin(Request $request)
    {
        $requestData = $request->all();

        $validator = Validator::make($requestData, [
            'name' => 'required',
            'email' => 'email|required',
            'password' => 'min:6|required_with:confirm_password|same:confirm_password',
            'categories_ids' => 'nullable',
            'store_name' => 'required',
            'store_id' => 'required',
            'store_url' => 'required',
            'city_id' => 'nullable',
            'pan_number' => 'nullable',
            'commission' => 'nullable',
            'national_id_card' => 'required|mimes:jpeg,jpg,png,gif,pdf',
            'address_proof' => 'nullable|mimes:jpeg,jpg,png,gif,pdf',
            'store_logo' => 'required|mimes:jpeg,jpg,png,gif,pdf',
            'store_description' => 'required',

            'lat_long' => 'required',
            'store_location' => 'required',
            'store_city' => 'required',
            'tax_name' => 'required',
            'tax_number' => 'nullable',
            'mobile' => 'nullable',
            'pan_img' => 'required|mimes:jpeg,jpg,png,gif,pdf',
            'fssai_img' => 'nullable|mimes:jpeg,jpg,png,gif,pdf',
            'store_images' => 'nullable|array',
            'store_images.*' => 'nullable|mimes:jpeg,jpg,png,gif,pdf',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        DB::beginTransaction();
        try {

            $adminUser = auth()->guard('api')->user();

            if (!$adminUser) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Admin authentication required.',
                    'data' => null
                ], 401);
            }

            $seller = Seller::where('admin_id', $adminUser->id)->first();

            if (!$seller) {
                $seller = new Seller();
            }

            Admin::where('id', $adminUser->id)->update([
                'username' => $request->name,
                'email' => $request->email,
                'password' => bcrypt($request->password),
                'created_by' => 0,
            ]);

            $seller->admin_id = $adminUser->id;
            $seller->name = $request->name;
            $seller->store_id = $request->store_id;
            $seller->slug = $request->store_name;
            $seller->store_name = $request->store_name;
            $seller->email = $request->email;
            $seller->status = Seller::$statusRegistered;

            $seller->store_location = $request->store_location;
            $seller->store_city = $request->store_city;
            $seller->tax_name = $request->tax_name;
            $seller->tax_number = $request->tax_number ?? null;
            $seller->lat_long = $request->lat_long;

            $seller->store_url = $request->store_url ?? null;

            $seller->categories = $request->categories_ids ?? null;
            $seller->pan_number = $request->pan_number;
            $seller->fssai_number = $request->fssai_number ?? null;
            $seller->aadhar_number = $request->aadhar_number ?? null;
            $seller->category_name = $request->category_name ?? null;


            $seller->city_id = $request->city_id;
            $seller->store_description = $request->store_description;
            $seller->commission = $request->commission ?? 20;

            // Snapshot the admin-configured vendor GST + commission for
            // this seller's store category. The settlement service still
            // resolves the live rate from settings for ongoing payouts;
            // these columns are the historical record of what applied at
            // registration.
            if (\Schema::hasColumn('sellers', 'vendor_gst_percent')) {
                $seller->vendor_gst_percent = $this->resolveVendorGstPercentForStore($request->store_id);
            }
            if (\Schema::hasColumn('sellers', 'vendor_commission_percent')) {
                $seller->vendor_commission_percent = $this->resolveVendorCommissionPercentForStore($request->store_id);
            }



            // Upload files...
            if ($request->hasFile('store_logo')) {
                $seller->logo = MediaUploadService::uploadWithFullUrl($request->file('store_logo'), 'sellers');
            }

            if ($request->mobile) {
                $seller->mobile = $request->mobile;
            }

            if ($request->hasFile('pan_img')) {
                $seller->pan_img = MediaUploadService::uploadWithFullUrl($request->file('pan_img'), 'sellers');
            }

            if ($request->hasFile('fssai_img')) {
                $seller->fssai_img = MediaUploadService::uploadWithFullUrl($request->file('fssai_img'), 'sellers');
            }

            $imgs = [];
            if ($request->hasFile('store_images')) {
                foreach ($request->file('store_images') as $file) {
                    $imgs[] = MediaUploadService::uploadWithFullUrl($file, 'sellers');
                }
            }
            $seller->store_images = json_encode($imgs);

            if ($request->hasFile('national_id_card')) {
                $seller->national_identity_card = MediaUploadService::uploadWithFullUrl($request->file('national_id_card'), 'sellers');
            }

            if ($request->hasFile('address_proof')) {
                $seller->address_proof = MediaUploadService::uploadWithFullUrl($request->file('address_proof'), 'sellers');
            }

            $seller->save();

            // Save commissions
            // $categories = explode(',', $request->categories_ids);
            // foreach ($categories as $cat) {
            //     $sc = new SellerCommission();
            //     $sc->seller_id = $seller->id;
            //     $sc->category_id = $cat;
            //     $sc->save();
            // }

            DB::commit();
            return CommonHelper::responseSuccess("Seller Registration Successful!");


        } catch (\Exception $e) {
            DB::rollBack();
            Log::error("Seller Register Error:", [$e->getMessage()]);
            return CommonHelper::responseError("Something went wrong!");
        }
    }


    /**
     * Update Seller from Admin - Only updates fields that are provided in the request
     */
    public function sellerUpdateFromAdmin(Request $request, $id)
    {
        $requestData = $request->all();

        // Validation - only validate fields that are present in the request
        $rules = [];

        if ($request->has('name')) {
            $rules['name'] = 'required';
        }
        if ($request->has('email')) {
            $rules['email'] = 'email|required';
        }
        if ($request->filled('password')) {
            $rules['password'] = 'min:6|required_with:confirm_password|same:confirm_password';
        }
        if ($request->has('store_name')) {
            $rules['store_name'] = 'required';
        }
        if ($request->has('store_description')) {
            $rules['store_description'] = 'required';
        }
        if ($request->has('lat_long')) {
            $rules['lat_long'] = 'required';
        }
        if ($request->has('store_location')) {
            $rules['store_location'] = 'required';
        }
        if ($request->has('store_city')) {
            $rules['store_city'] = 'required';
        }
        if ($request->has('tax_name')) {
            $rules['tax_name'] = 'required';
        }
        if ($request->hasFile('national_id_card')) {
            $rules['national_id_card'] = 'mimes:jpeg,jpg,png,gif,pdf';
        }
        if ($request->hasFile('address_proof')) {
            $rules['address_proof'] = 'mimes:jpeg,jpg,png,gif,pdf';
        }
        if ($request->hasFile('store_logo')) {
            $rules['store_logo'] = 'mimes:jpeg,jpg,png,gif,pdf';
        }
        if ($request->hasFile('pan_img')) {
            $rules['pan_img'] = 'mimes:jpeg,jpg,png,gif,pdf';
        }
        if ($request->hasFile('fssai_img')) {
            $rules['fssai_img'] = 'mimes:jpeg,jpg,png,gif,pdf';
        }
        if ($request->hasFile('store_images')) {
            $rules['store_images'] = 'array';
            $rules['store_images.*'] = 'mimes:jpeg,jpg,png,gif,pdf';
        }

        $validator = Validator::make($requestData, $rules);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        DB::beginTransaction();
        try {
            $seller = Seller::find($id);

            if (!$seller) {
                return CommonHelper::responseError("Seller not found.");
            }

            // Update Admin record if name, email, or password is provided
            if ($seller->admin_id) {
                $adminUpdateData = [];
                if ($request->has('name')) {
                    $adminUpdateData['username'] = $request->name;
                }
                if ($request->has('email')) {
                    $adminUpdateData['email'] = $request->email;
                }
                if ($request->filled('password')) {
                    $adminUpdateData['password'] = bcrypt($request->password);
                }
                if (!empty($adminUpdateData)) {
                    Admin::where('id', $seller->admin_id)->update($adminUpdateData);
                }
            }

            // Update seller fields only if they are provided in the request
            if ($request->has('name')) {
                $seller->name = $request->name;
            }
            if ($request->has('store_id')) {
                $seller->store_id = $request->store_id;
            }
            if ($request->has('store_name')) {
                $seller->slug = $request->store_name;
                $seller->store_name = $request->store_name;
            }
            if ($request->has('email')) {
                $seller->email = $request->email;
            }
            if ($request->has('mobile')) {
                $seller->mobile = $request->mobile;
            }
            if ($request->has('store_location')) {
                $seller->store_location = $request->store_location;
            }
            if ($request->has('store_city')) {
                $seller->store_city = $request->store_city;
            }
            if ($request->has('tax_name')) {
                $seller->tax_name = $request->tax_name;
            }
            if ($request->has('tax_number')) {
                $seller->tax_number = $request->tax_number;
            }
            if ($request->has('lat_long')) {
                $seller->lat_long = $request->lat_long;
            }
            if ($request->has('store_url')) {
                $seller->store_url = $request->store_url;
            }
            if ($request->has('categories_ids')) {
                $seller->categories = $request->categories_ids;
            }
            if ($request->has('pan_number')) {
                $seller->pan_number = $request->pan_number;
            }
            if ($request->has('fssai_number')) {
                $seller->fssai_number = $request->fssai_number;
            }
            if ($request->has('aadhar_number')) {
                $seller->aadhar_number = $request->aadhar_number;
            }
            if ($request->has('category_name')) {
                $seller->category_name = $request->category_name;
            }
            if ($request->has('city_id')) {
                $seller->city_id = $request->city_id;
            }
            if ($request->has('store_description')) {
                $seller->store_description = $request->store_description;
            }
            if ($request->has('commission')) {
                $seller->commission = $request->commission;
            }
            if ($request->has('status')) {
                $seller->status = $request->status;
            }
            if ($request->has('remark')) {
                $seller->remark = $request->remark;
            }

            // Upload files only if they are provided
            if ($request->hasFile('store_logo')) {
                $seller->logo = MediaUploadService::uploadWithFullUrl($request->file('store_logo'), 'sellers');
            }

            if ($request->hasFile('pan_img')) {
                $seller->pan_img = MediaUploadService::uploadWithFullUrl($request->file('pan_img'), 'sellers');
            }

            if ($request->hasFile('fssai_img')) {
                $seller->fssai_img = MediaUploadService::uploadWithFullUrl($request->file('fssai_img'), 'sellers');
            }

            // Only update store_images if new files are uploaded
            if ($request->hasFile('store_images')) {
                $imgs = [];
                foreach ($request->file('store_images') as $file) {
                    $imgs[] = MediaUploadService::uploadWithFullUrl($file, 'sellers');
                }
                $seller->store_images = json_encode($imgs);
            }

            if ($request->hasFile('national_id_card')) {
                $seller->national_identity_card = MediaUploadService::uploadWithFullUrl($request->file('national_id_card'), 'sellers');
            }

            if ($request->hasFile('address_proof')) {
                $seller->address_proof = MediaUploadService::uploadWithFullUrl($request->file('address_proof'), 'sellers');
            }

            $seller->save();

            DB::commit();
            return CommonHelper::responseSuccess("Seller Updated Successfully!");

        } catch (\Exception $e) {
            DB::rollBack();
            Log::error("Seller Update Error:", [$e->getMessage()]);
            return CommonHelper::responseError("Something went wrong!");
        }
    }


    public function getCategoriesAllData(Request $request)
    {
        try {
            $admin = auth()->guard('api')->user();

            if (!$admin) {
                return CommonHelper::responseError("Invalid token or unauthorized access.");
            }

            $categories_data = Category::select('id', 'name')->get();
            $data = $categories_data;

            return CommonHelper::responseSuccessWithData("Data fetched successfully", $data);

        } catch (\Exception $e) {
            Log::error("Get Data Error Categories get api:", [$e->getMessage()]);
            return CommonHelper::responseError("Something went wrong!");
        }
    }

    /**
     * Update Seller Personal Details
     * Fields: name, email, aadhar_number, aadhar_image, pan_number, pan_image, fssai_number, fssai_image
     */
    public function updateSellerPersonalDetails(Request $request)
    {
        try {
            $admin = auth()->guard('api')->user();

            if (!$admin) {
                return CommonHelper::responseError("Invalid token or unauthorized access.");
            }

            $seller = Seller::where('admin_id', $admin->id)->first();

            if (!$seller) {
                return CommonHelper::responseError("Seller profile not found.");
            }

            // Build validation rules dynamically
            $rules = [];

            if ($request->has('name')) {
                $rules['name'] = 'required|string|max:255';
            }

            // Only validate email uniqueness if the email is being changed
            if ($request->has('email')) {
                if ($seller->email != $request->email) {
                    // Email is changing - validate uniqueness
                    $rules['email'] = 'required|email|unique:sellers,email,' . $seller->id;
                } else {
                    // Email is same - just validate format
                    $rules['email'] = 'required|email';
                }
            }

            if ($request->has('aadhar_number')) {
                $rules['aadhar_number'] = 'required|string';
            }

            if ($request->has('pan_number')) {
                $rules['pan_number'] = 'required|string';
            }

            // if ($request->has('fssai_number')) {
            //     $rules['fssai_number'] = 'required|string';
            // }

            // Validate file uploads only if new files are provided
            if ($request->hasFile('national_id_card')) {
                $rules['national_id_card'] = 'mimes:jpeg,jpg,png,gif,pdf|max:10240';
            }

            if ($request->hasFile('pan_img')) {
                $rules['pan_img'] = 'mimes:jpeg,jpg,png,gif,pdf|max:10240';
            }

            // if ($request->hasFile('fssai_img')) {
            //     $rules['fssai_img'] = 'mimes:jpeg,jpg,png,gif,pdf|max:10240';
            // }

            $validator = Validator::make($request->all(), $rules);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            DB::beginTransaction();

            // Track if any field was actually updated
            $hasUpdates = false;

            // Update Admin record if name or email has actually changed
            if ($seller->admin_id) {
                $adminUpdateData = [];

                if ($request->has('name') && $seller->name != $request->name) {
                    $adminUpdateData['username'] = $request->name;
                }

                if ($request->has('email') && $seller->email != $request->email) {
                    $adminUpdateData['email'] = $request->email;
                }

                if (!empty($adminUpdateData)) {
                    Admin::where('id', $seller->admin_id)->update($adminUpdateData);
                }
            }

            // Update seller personal fields
            if ($request->has('name') && $seller->name != $request->name) {
                $seller->name = $request->name;
                $hasUpdates = true;
            }

            if ($request->has('email') && $seller->email != $request->email) {
                $seller->email = $request->email;
                $hasUpdates = true;
            }

            if ($request->has('aadhar_number') && $seller->aadhar_number != $request->aadhar_number) {
                $seller->aadhar_number = $request->aadhar_number;
                $hasUpdates = true;
            }

            if ($request->has('pan_number') && $seller->pan_number != $request->pan_number) {
                $seller->pan_number = $request->pan_number;
                $hasUpdates = true;
            }

            if ($request->has('fssai_number') && $seller->fssai_number != $request->fssai_number) {
                $seller->fssai_number = $request->fssai_number;
                $hasUpdates = true;
            }

            // Handle file uploads - only update if new file is uploaded
            if ($request->hasFile('national_id_card')) {
                $seller->national_identity_card = MediaUploadService::uploadWithFullUrl($request->file('national_id_card'), 'sellers');
                $hasUpdates = true;
            }

            if ($request->hasFile('pan_img')) {
                $seller->pan_img = MediaUploadService::uploadWithFullUrl($request->file('pan_img'), 'sellers');
                $hasUpdates = true;
            }

            if ($request->hasFile('fssai_img')) {
                $seller->fssai_img = MediaUploadService::uploadWithFullUrl($request->file('fssai_img'), 'sellers');
                $hasUpdates = true;
            }

            // If seller status is 2 (rejected) and fields were updated, reset to 0 (pending) and clear remark
            if ($seller->status == 2 && $hasUpdates) {
                $seller->status = 0;
                $seller->remark = null;
            }

            $seller->save();

            DB::commit();

            return CommonHelper::responseSuccess("Personal details updated successfully!");

        } catch (\Exception $e) {
            DB::rollBack();
            Log::error("Seller Personal Details Update Error:", [$e->getMessage()]);
            return CommonHelper::responseError("Something went wrong!");
        }
    }

    /**
     * Update Seller Store Details
     * Fields: store_name, store_id, store_location, store_city, tax_name, tax_number,
     * lat_long, store_url, categories_ids, city_id, store_description, commission,
     * store_logo, store_images, address_proof, mobile
     */
    public function updateSellerStoreDetails(Request $request)
    {
        try {
            $admin = auth()->guard('api')->user();

            if (!$admin) {
                return CommonHelper::responseError("Invalid token or unauthorized access.");
            }

            $seller = Seller::where('admin_id', $admin->id)->first();

            if (!$seller) {
                return CommonHelper::responseError("Seller profile not found.");
            }

            // Build validation rules dynamically
            $rules = [];

            if ($request->has('store_name')) {
                $rules['store_name'] = 'required|string|max:255';
            }

            if ($request->has('store_id')) {
                $rules['store_id'] = 'required|exists:stores,id';
            }

            if ($request->has('mobile')) {
                $rules['mobile'] = 'required|string';
            }

            if ($request->has('store_location')) {
                $rules['store_location'] = 'required|string';
            }

            if ($request->has('store_city')) {
                $rules['store_city'] = 'required|string';
            }

            if ($request->has('tax_name')) {
                $rules['tax_name'] = 'required|string';
            }

            if ($request->has('tax_number')) {
                $rules['tax_number'] = 'required|string';
            }

            if ($request->has('lat_long')) {
                $rules['lat_long'] = 'required|string';
            }

            if ($request->has('store_url')) {
                $rules['store_url'] = 'nullable|url';
            }

            if ($request->has('categories_ids')) {
                $rules['categories_ids'] = 'required|string';
            }

            if ($request->has('city_id')) {
                $rules['city_id'] = 'required|exists:cities,id';
            }

            if ($request->has('store_description')) {
                $rules['store_description'] = 'nullable|string';
            }

            if ($request->has('commission')) {
                $rules['commission'] = 'nullable|numeric|min:0|max:100';
            }

            // Validate file uploads only if new files are provided
            if ($request->hasFile('store_logo')) {
                $rules['store_logo'] = 'mimes:jpeg,jpg,png,gif|max:10240';
            }

            if ($request->hasFile('address_proof')) {
                $rules['address_proof'] = 'mimes:jpeg,jpg,png,gif,pdf|max:10240';
            }

            if ($request->hasFile('store_images')) {
                $rules['store_images'] = 'array';
                $rules['store_images.*'] = 'mimes:jpeg,jpg,png,gif|max:10240';
            }

            $validator = Validator::make($request->all(), $rules);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            DB::beginTransaction();

            // Track if any field was actually updated
            $hasUpdates = false;

            // Update seller store fields - only if value actually changed
            if ($request->has('store_name') && $seller->store_name != $request->store_name) {
                $seller->store_name = $request->store_name;
                $seller->slug = $request->store_name;
                $hasUpdates = true;
            }

            if ($request->has('store_id') && $seller->store_id != $request->store_id) {
                $seller->store_id = $request->store_id;
                $hasUpdates = true;
            }

            if ($request->has('mobile') && $seller->mobile != $request->mobile) {
                $seller->mobile = $request->mobile;
                $hasUpdates = true;
            }

            if ($request->has('store_location') && $seller->store_location != $request->store_location) {
                $seller->store_location = $request->store_location;
                $hasUpdates = true;
            }

            if ($request->has('store_city') && $seller->store_city != $request->store_city) {
                $seller->store_city = $request->store_city;
                $hasUpdates = true;
            }

            if ($request->has('tax_name') && $seller->tax_name != $request->tax_name) {
                $seller->tax_name = $request->tax_name;
                $hasUpdates = true;
            }

            if ($request->has('tax_number') && $seller->tax_number != $request->tax_number) {
                $seller->tax_number = $request->tax_number;
                $hasUpdates = true;
            }

            if ($request->has('lat_long') && $seller->lat_long != $request->lat_long) {
                $seller->lat_long = $request->lat_long;
                $hasUpdates = true;
            }

            if ($request->has('store_url') && $seller->store_url != $request->store_url) {
                $seller->store_url = $request->store_url;
                $hasUpdates = true;
            }

            if ($request->has('categories_ids') && $seller->categories != $request->categories_ids) {
                $seller->categories = $request->categories_ids;
                $hasUpdates = true;
            }

            if ($request->has('city_id') && $seller->city_id != $request->city_id) {
                $seller->city_id = $request->city_id;
                $hasUpdates = true;
            }

            if ($request->has('store_description') && $seller->store_description != $request->store_description) {
                $seller->store_description = $request->store_description;
                $hasUpdates = true;
            }

            if ($request->has('commission') && $seller->commission != $request->commission) {
                $seller->commission = $request->commission;
                $hasUpdates = true;
            }

            // Handle file uploads - only update if new file is uploaded
            if ($request->hasFile('store_logo')) {
                $seller->logo = MediaUploadService::uploadWithFullUrl($request->file('store_logo'), 'sellers');
                $hasUpdates = true;
            }

            if ($request->hasFile('address_proof')) {
                $seller->address_proof = MediaUploadService::uploadWithFullUrl($request->file('address_proof'), 'sellers');
                $hasUpdates = true;
            }

            // Handle store_images - support both new uploads and existing URLs
            if ($request->hasFile('store_images')) {
                $imgs = [];

                // Get existing images from database
                $existingImages = json_decode($seller->store_images, true) ?? [];

                // Collect existing URLs from request (Laravel converts indexed params to array)
                $existingUrls = [];

                if ($request->has('store_images_urls')) {
                    $rawUrls = $request->input('store_images_urls');

                    // If it's an array, use it directly; if string, wrap in array
                    if (is_array($rawUrls)) {
                        $existingUrls = $rawUrls;
                    } else {
                        $existingUrls = [$rawUrls];
                    }
                }

                // Add existing URLs first
                if (!empty($existingUrls)) {
                    $imgs = $existingUrls;  // Full URLs already stored in database
                }

                // Then add new uploaded images
                foreach ($request->file('store_images') as $file) {
                    $imgs[] = MediaUploadService::uploadWithFullUrl($file, 'sellers');
                }

                // Check if images array has changed
                if ($existingImages != $imgs) {
                    $seller->store_images = json_encode($imgs);
                    $hasUpdates = true;
                    Log::info("Store images updated (with new files)", ['new_images' => $imgs]);
                }
            } else {
                // Only existing URLs sent (no new uploads)
                // Laravel converts store_images_urls[0], store_images_urls[1] to an array
                $existingUrls = [];

                if ($request->has('store_images_urls')) {
                    $rawUrls = $request->input('store_images_urls');

                    // If it's an array, use it directly; if string, wrap in array
                    if (is_array($rawUrls)) {
                        $existingUrls = $rawUrls;
                    } else {
                        $existingUrls = [$rawUrls];
                    }
                }

                Log::info("Existing URLs from request:", ['urls' => $existingUrls]);

                // Get current images from database
                $existingImages = json_decode($seller->store_images, true) ?? [];

                // Sort both arrays to ensure proper comparison
                sort($existingUrls);
                sort($existingImages);

                // Log for debugging
                Log::info("Store Images Update Check:", [
                    'request_urls' => $existingUrls,
                    'db_urls' => $existingImages,
                    'are_different' => $existingImages != $existingUrls
                ]);

                // Update if:
                // 1. URLs are sent and different from current images, OR
                // 2. URLs array is empty (user removed all images) and DB has images
                if ((!empty($existingUrls) && $existingImages != $existingUrls) ||
                    (empty($existingUrls) && !empty($existingImages))) {
                    // Store full URLs directly
                    $seller->store_images = json_encode($existingUrls);
                    $hasUpdates = true;
                    Log::info("Store images updated", ['new_images' => $existingUrls]);
                }
            }

            // If seller status is 2 (rejected) and fields were updated, reset to 0 (pending) and clear remark
            if ($seller->status == 2 && $hasUpdates) {
                $seller->status = 0;
                $seller->remark = null;
            }

            $seller->save();

            DB::commit();

            return CommonHelper::responseSuccess("Store details updated successfully!");

        } catch (\Exception $e) {
            DB::rollBack();
            Log::error("Seller Store Details Update Error:", [$e->getMessage()]);
            return CommonHelper::responseError("Something went wrong!");
        }
    }

    public function getSellerRegistrationDataForAdmin($id)
    {
        try {

            $seller = Seller::with('store')->where('id', $id)->first();

            if (!$seller) {
                return CommonHelper::responseError("Seller profile not found.");
            }

            $storeImages = [];
            if (!empty($seller->store_images)) {
                $decoded = json_decode($seller->store_images, true);
                if (is_array($decoded)) {
                    $storeImages = array_map(function ($img) {
                        return str_starts_with($img, 'http') ? $img : asset('storage/' . $img);
                    }, $decoded);
                }
            }

            $data = [
                "seller" => [
                    "id" => $seller->id,
                    "name" => $seller->name,
                    "email" => $seller->email,
                    "store_name" => $seller->store_name,
                    "store_description" => $seller->store_description,
                    "store_location" => $seller->store_location,
                    "store_city" => $seller->store_city,
                    "tax_name" => $seller->tax_name,
                    "tax_number" => $seller->tax_number,
                    "pan_number" => $seller->pan_number,
                    "city_id" => $seller->city_id,
                    "commission" => $seller->commission,
                    "lat_long" => $seller->lat_long,
                    "store_id" => $seller->store_id,
                    "store" => $seller->store ? ["name" => $seller->store->name] : null,
                    "categories_ids" => $seller->categories,
                    "store_url" => $seller->store_url,
                    "is_approved" => $seller->status,

                    "logo_url" => $seller->logo ? (str_starts_with($seller->logo, 'http') ? $seller->logo : asset('storage/' . $seller->logo)) : null,
                    "pan_img_url" => $seller->pan_img ? (str_starts_with($seller->pan_img, 'http') ? $seller->pan_img : asset('storage/' . $seller->pan_img)) : null,
                    "fssai_img_url" => $seller->fssai_img ? (str_starts_with($seller->fssai_img, 'http') ? $seller->fssai_img : asset('storage/' . $seller->fssai_img)) : null,

                    "store_images" => $storeImages,

                    "national_id_card" => $seller->national_identity_card ? (str_starts_with($seller->national_identity_card, 'http') ? $seller->national_identity_card : asset('storage/' . $seller->national_identity_card)) : null,
                    "aadhar_number" => $seller->aadhar_number,
                    "aadhar_status" => $seller->aadhar_status ?? 0,

                    "fssai_number" => $seller->fssai_number,
                    "fssai_status" => $seller->fssai_status ?? 0,

                    "pan_status" => $seller->pan_status ?? 0,

                    "agreement_status" => $seller->agreement_status ?? 0,
                    "agreement_pdf_url" => $seller->agreement_pdf_url ? (str_starts_with($seller->agreement_pdf_url, 'http') ? $seller->agreement_pdf_url : asset('storage/' . $seller->agreement_pdf_url)) : null,

                    "address_proof" => $seller->address_proof ? (str_starts_with($seller->address_proof, 'http') ? $seller->address_proof : asset('storage/' . $seller->address_proof)) : null,
                ]
            ];

            return CommonHelper::responseSuccessWithData("Data fetched successfully", $data);

        } catch (\Exception $e) {
            Log::error("Seller Get Data Error:", [$e->getMessage()]);
            return CommonHelper::responseError("Something went wrong!");
        }
    }




    public function updateShopLocationLatLong(Request $request)
    {
        try {
            $admin = auth()->guard('api')->user();

            if (!$admin) {
                return CommonHelper::responseError("Invalid token or unauthorized access.");
            }

            $seller = Seller::where('admin_id', $admin->id)->first();

            if (!$seller) {
                return CommonHelper::responseError("Seller not found.");
            }

            Seller::where('admin_id', $admin->id)->update([
                'store_location' => $request->store_location,
                'lat_long' => $request->latitude . ',' . $request->longitude,
            ]);

            return CommonHelper::responseSuccessWithData("Location updated successfully.", [
                'store_location' => $request->store_location,
                'lat' => $request->latitude,
                'lng' => $request->longitude,
            ]);

        } catch (\Exception $e) {
            Log::error("Error:", [$e->getMessage()]);
            return CommonHelper::responseError("Something went wrong!");
        }
    }


    public function updateShopStatusOfSeller(Request $request)
    {
        try {
            $admin = auth()->guard('api')->user();

            if (!$admin) {
                return CommonHelper::responseError("Invalid token or unauthorized access.");
            }

            Seller::where('admin_id', $admin->id)->update([
                'shop_status' => $request->status
            ]);

            return response()->json([
                'status' => 1,
                'message' => 'Status updated successfully'
            ]);

        } catch (\Exception $e) {
            Log::error("Error:", [$e->getMessage()]);
            return CommonHelper::responseError("Something went wrong!");
        }
    }

    public function getShopStatusOfSeller(Request $request)
    {
        try {
            $admin = auth()->guard('api')->user();

            if (!$admin) {
                return CommonHelper::responseError("Invalid token or unauthorized access.");
            }

            $seller_status = Seller::where('admin_id', $admin->id)->value('shop_status');

            return response()->json([
                'message' => "shop status get success",
                'shop_status' => $seller_status,
            ]);

        } catch (\Exception $e) {
            Log::error("Error:", [$e->getMessage()]);
            return CommonHelper::responseError("Something went wrong!");
        }
    }


    public function getShopTimings(Request $request)
    {
        try {
            $admin = auth()->guard('api')->user();

            if (!$admin) {
                return CommonHelper::responseError("Invalid token or unauthorized access.");
            }

            $seller = Seller::where('admin_id', $admin->id)
                ->select('shop_opening_time', 'shop_closing_time')
                ->first();

            if (!$seller) {
                return CommonHelper::responseError("Seller not found.");
            }

            return response()->json([
                'status'  => 1,
                'message' => 'Shop timings fetched successfully',
                'data'    => [
                    'shop_opening_time' => $seller->shop_opening_time,
                    'shop_closing_time' => $seller->shop_closing_time,
                ],
            ]);

        } catch (\Exception $e) {
            Log::error("getShopTimings Error:", [$e->getMessage()]);
            return CommonHelper::responseError("Something went wrong!");
        }
    }

    public function updateShopTimings(Request $request)
    {
        try {
            $admin = auth()->guard('api')->user();

            if (!$admin) {
                return CommonHelper::responseError("Invalid token or unauthorized access.");
            }

            $validator = Validator::make($request->all(), [
                'shop_opening_time' => 'required|date_format:H:i:s',
                'shop_closing_time' => 'required|date_format:H:i:s',
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            Seller::where('admin_id', $admin->id)->update([
                'shop_opening_time' => $request->shop_opening_time,
                'shop_closing_time' => $request->shop_closing_time,
            ]);

            return response()->json([
                'status'  => 1,
                'message' => 'Shop timings updated successfully',
            ]);

        } catch (\Exception $e) {
            Log::error("updateShopTimings Error:", [$e->getMessage()]);
            return CommonHelper::responseError("Something went wrong!");
        }
    }

    public function getCategoriesByStoreId($storeId)
    {
        try {
            if (!$storeId) {
                return response()->json([
                    'success' => false,
                    'message' => 'store_id is required'
                ], 400);
            }

            $categoryGroupIds = CategoryGroupStore::where('store_id', $storeId)
                ->pluck('category_group_id');

            // dd($categoryGroupIds);

            if ($categoryGroupIds->isEmpty()) {
                return response()->json([
                    'success' => true,
                    'categories' => []
                ]);
            }

            // 2️⃣ Get sub-category groups BELONGING to these category-groups
            $subCategoryGroups = SubCategoryGroup::whereIn('category_group_id', $categoryGroupIds)->get();

            // dd($subCategoryGroups);

            // 3️⃣ Collect all category IDs inside all sub-category groups
            $categoryIds = [];

            foreach ($subCategoryGroups as $group) {
                if (!empty($group->subcategory_ids)) {
                    $ids = explode(',', $group->subcategory_ids);
                    $categoryIds = array_merge($categoryIds, $ids);
                }
            }

            $categoryIds = array_unique($categoryIds);

            // 4️⃣ Fetch final categories
            $categories = Category::whereIn('id', $categoryIds)->get();

            return response()->json([
                'success' => true,
                'store_id' => $storeId,
                'categories' => $categories
            ]);

        } catch (\Exception $e) {
            Log::error("Get Categories by Store ID Error:", [$e->getMessage()]);

            return response()->json([
                'success' => false,
                'message' => 'Something went wrong'
            ], 500);
        }
    }



    public function dataBasedOnStoreSelectionSeller(Request $request)
    {
        $storeId = $request->store_id;

        $categoryGroupIds = CategoryGroupStore::where('store_id', $storeId)
            ->pluck('category_group_id');

        $query = CategoryGroup::whereIn('id', $categoryGroupIds);

        // search on name/title fields
        $data = $this->applyPaginationAndSearch($query, $request, ['name']);

        return response()->json([
            "success" => true,
            "data" => $data,
        ]);
    }




    public function dataBasedOnStoreSelectionSellerAuthToken(Request $request)
    {

        $seller = auth()->user()->seller;

        $query = CategoryGroup::where('seller_id', $seller->id);

        // search on name/title fields
        $data = $this->applyPaginationAndSearch($query, $request, ['name']);

        return response()->json([
            "success" => true,
            "data" => $data,
        ]);
    }



    public function dataBasedOnCategoryGroupSelectionSeller(Request $request)
    {
        $id = $request->category_group_id;

        // dd($id);

        $query = SubCategoryGroup::where('category_group_id', $id);

        // apply search & pagination
        $data = $this->applyPaginationAndSearch($query, $request, ['name']);

        return response()->json([
            "success" => true,
            "data" => $data,
        ]);
    }


    public function dataBasedOnSubCategoryGroupSelectionSeller(Request $request)
    {
        $id = $request->sub_category_group_id;

        $categoryGroup = SubCategoryGroup::find($id);

        if (!$categoryGroup) {
            return response()->json([
                "success" => true,
                "data" => []
            ]);
        }

        $ids = explode(',', $categoryGroup->subcategory_ids);

        $query = Category::whereIn('id', $ids);

        // apply pagination + search
        $data = $this->applyPaginationAndSearch($query, $request, ['name']);

        return response()->json([
            "success" => true,
            "data" => $data,
        ]);
    }


    private function applyPaginationAndSearch($query, Request $request, $searchFields = [])
    {
        if ($request->has('search') && $request->search !== '') {
            $search = $request->search;

            $query->where(function ($q) use ($search, $searchFields) {
                foreach ($searchFields as $field) {
                    $q->orWhere($field, 'LIKE', "%{$search}%");
                }
            });
        }

        $perPage = $request->input('per_page', 10);

        return $query->paginate($perPage);
    }

    public function save(Request $request)
    {


        $admin = auth()->guard('api')->user();


        if (!$admin) {
            return CommonHelper::responseError("Invalid token or unauthorized access.");
        }

        $seller_data_for_id = Seller::where('admin_id', $admin->id)->first();

        if (!$seller_data_for_id) {
            return CommonHelper::responseError("Seller profile not found.");
        }


        $validator = Validator::make($request->all(), [
            'name' => [
                'required',
                Rule::unique('products')->where(function ($query) use ($request) {
                    $query->where('seller_id', $request->seller_id);
                })
            ],
            'store_id' => 'required',
            'category_id' => 'required',
            'category_group_id' => 'required',
            'sub_category_group_id' => 'required',
            'item_type_id' => 'required',
            'brand_id' => 'required',
            'description' => 'required',
            'tags' => 'nullable',
            'made_in' => 'required|string',
            'other_info' => 'nullable',
            'manufacturer' => 'nullable',
            'tax' => 'nullable',
            'is_unlimited_stock' => 'required',

            'type' => 'required',
            'packet_measurement.*' => ['required_if:type,packet', 'numeric', Rule::notIn([0]),],
            'packet_price.*' => ['required_if:type,packet', 'numeric'],
            'packet_stock.*' => [
                'required_if:type,packet',
                'numeric',
                function ($attribute, $value, $fail) use ($request) {
                    $index = explode('.', $attribute)[1];
                    $status = $request->input("packet_status.{$index}", 1);

                    if ($request->input('is_unlimited_stock') == 0 && $value == 0 && $request->input('type') == 'packet' && $status != 0) {
                        $fail($attribute . ' must be greater than 0 when is_unlimited_stock is 0 and status is not "Sold Out".');
                    }
                },
            ],
            'packet_stock_unit_id.*' => ['required_if:type,packet', 'numeric'],

            'loose_measurement.*' => ['required_if:type,loose', 'numeric', Rule::notIn([0]),],
            'loose_price.*' => ['required_if:type,loose', 'numeric'],
            'loose_stock.*' => [
                'required_if:type,loose',
                'numeric',
                function ($attribute, $value, $fail) use ($request) {
                    $index = explode('.', $attribute)[1];
                    $status = $request->input('status', $request->input("loose_status.{$index}", 1));

                    if ($request->input('is_unlimited_stock') == 0 && strval($value) === '0' && $request->input('type') == 'loose' && intval($status) !== 0) {
                        $fail($attribute . ' must be greater than 0 when is_unlimited_stock is 0 and status is not "Sold Out".');
                    }
                },
            ],
            'loose_stock_unit_id' => ['required_if:type,loose', 'nullable', 'numeric'],

            'barcode' => 'nullable|unique:products,barcode',
        ], [
            'name.unique' => 'The product name has already been taken.',
            'category_id.required' => 'The Category name field is required.',

            'store_id.required' => 'The Store Selcetion is required.',
            'sub_category_group_id.required' => 'The Sub Category Group is required.',
            'category_group_id.required' => 'The Category Group is required.',

            'packet_measurement.*.required_if' => 'The Packet Measurement is required when the type is "Packet".',
            'packet_measurement.*.numeric' => 'The Packet Measurement  must be a number.',
            'packet_measurement.*.not_in' => 'The Packet Measurement must not be zero.',
            'packet_stock.*.required_if' => 'The Packet Stock is required when the type is "Packet".',
            'packet_stock.*.not_in' => 'The Packet Stock must not be zero.',
            'packet_stock_unit_id.*.required_if' => 'The Packet Stock Unit is required when the type is "Packet".',

            'loose_measurement.*.required_if' => 'The Loose Measurement is required when the type is "Loose".',
            'loose_measurement.*.numeric' => 'The Loose Measurement  must be a number.',
            'loose_measurement.*.not_in' => 'The Loose Measurement must not be zero.',
            'loose_stock_unit_id.required_if' => 'The Loose Stock Unit is required when the type is "Loose".',
            'loose_stock_unit_id.numeric' => 'The Loose Stock Unit must be a number.',

        ]);
        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $variations = array();
        if ($request->type == "packet") {
            foreach ($request->packet_measurement as $index => $item) {
                $data = array();
                $data['measurement'] = $request->packet_measurement[$index];
                $data['price'] = $request->packet_price[$index];
                $data['discounted_price'] = $request->discounted_price[$index];
                $data['status'] = $request->packet_status[$index];
                $data['stock'] = ($request->is_unlimited_stock == 0) ? $request->packet_stock[$index] : 0;

                $data['stock_unit_id'] = $request->packet_stock_unit_id[$index];
                $variations[] = $data;
            }
        } else {
            foreach ($request->loose_measurement as $index => $item) {
                $data = array();
                $data['measurement'] = $request->loose_measurement[$index];
                $data['price'] = $request->loose_price[$index];
                $data['discounted_price'] = $request->loose_discounted_price[$index];
                $variations[] = $data;
            }
        }
        if (count($variations) !== count(array_unique($variations, SORT_REGULAR))) {
            return CommonHelper::responseError("Variations are duplicate!");
        }

        DB::beginTransaction();

        try {
            $slug = $request->slug ?: preg_replace(
                '/\s+/',
                '-',
                trim(
                    preg_replace('/[^\p{L}\p{N} ]/u', '', $request->name)
                )
            );

            $count = Product::where('slug', 'LIKE', "{$slug}%")->count();

            $row_order = Product::max('row_order') + 1;
            $product = new Product();
            $product->name = $request->name;
            $product->slug = $count ? "{$slug}-{$count}" : $slug;
            $product->row_order = $row_order;

            $product->category_id = $request->category_id;
            $product->category_group_id = $request->category_group_id;
            $product->sub_category_group_id = $request->sub_category_group_id;
            $product->store_id = $request->store_id;



            $product->item_type_id = $request->item_type_id;
            $product->other_info = $request->other_info;


            $product->brand_id = $request->brand_id ?? "";
            $product->description = $request->description;
            $product->tags = $request->tags ?? "";
            $product->made_in = $request->made_in ?? "";
            $product->manufacturer = $request->manufacturer;
            $product->tax = $request->tax ?? "";



            $product->seller_id = $seller_data_for_id->id;


            $product->type = $request->type;
            $product->is_unlimited_stock = $request->is_unlimited_stock ?? 0;

            $product->status = 1;

            $product->return_status = $request->return_status;
            $product->return_days = $request->return_days;
            $product->cancelable_status = $request->cancelable_status;
            $product->till_status = $request->till_status;
            $product->total_allowed_quantity = $request->total_allowed_quantity;



            $product->meta_title = $request->meta_title ?? "";
            $product->meta_keywords = $request->meta_keywords ?? "";
            $product->schema_markup = $request->schema_markup ?? "";
            $product->meta_description = $request->meta_description ?? "";



            $image = '';
            if ($request->hasFile('image')) {
                $file = $request->file('image');
                $fileName = time() . '_' . rand(1111, 99999) . '.' . $file->getClientOriginalExtension();
                $image = Storage::disk('public')->putFileAs('products', $file, $fileName);
            } else {
                $image = $request->image;
            }
            $product->image = $image;
            $product->save();


            if ($request->hasFile('other_images')) {
                CommonHelper::uploadProductImages($request->file('other_images'), $product->id);
            }

            /*Variance*/
            if ($request->type == "packet") {

                foreach ($request->packet_measurement as $index => $item) {

                    $data = array();
                    $data['product_id'] = $product->id;
                    $data['type'] = $request->type;
                    $data['measurement'] = $request->packet_measurement[$index];
                    $data['price'] = $request->packet_price[$index];
                    $data['discounted_price'] = isset($request->discounted_price[$index]) ? $request->discounted_price[$index] : 0;
                    $data['status'] = $request->packet_status[$index] ?? 1;
                    $data['stock'] = ($request->is_unlimited_stock == 0) ? $request->packet_stock[$index] : 0;
                    $data['stock_unit_id'] = isset($request->packet_stock_unit_id[$index]) ? $request->packet_stock_unit_id[$index] : 0;

                    ProductVariant::insert($data);
                    $variant_id = DB::getPdo()->lastInsertId();
                    if ($request->hasFile('packet_variant_images_' . $index)) {
                        CommonHelper::uploadProductImages($request->file('packet_variant_images_' . $index), $product->id, $variant_id);
                    }
                }
            }

            if ($request->type == "loose") {
                foreach ($request->loose_measurement as $index => $item) {

                    $data = array();
                    $data['product_id'] = $product->id;
                    $data['type'] = $request->type;
                    $data['stock'] = ($request->is_unlimited_stock == 0) ? $request->loose_stock[$index] : 0;
                    $data['stock_unit_id'] = $request->loose_stock_unit_id;
                    $data['status'] = $request->status;
                    $data['measurement'] = $request->loose_measurement[$index];
                    $data['price'] = $request->loose_price[$index];

                    $data['discounted_price'] = isset($request->loose_discounted_price[$index]) ? $request->loose_discounted_price[$index] : 0;

                    ProductVariant::insert($data);
                    $variant_id = DB::getPdo()->lastInsertId();
                    if ($request->hasFile('loose_variant_images_' . $index)) {
                        CommonHelper::uploadProductImages($request->file('loose_variant_images_' . $index), $product->id, $variant_id);
                    }
                }
            }



            $product = Product::find($product->id);

            DB::commit();
        } catch (\Exception $e) {
            Log::info("Error : " . $e->getMessage());
            DB::rollBack();
            // throw $e;
            return CommonHelper::responseError($e->getMessage());
        }

        return CommonHelper::responseSuccess("Product Saved Successfully!");
    }

    /**
     * Resolve the admin-configured vendor GST percent for a given
     * store, using the same is_meat > is_food > is_super_mart >
     * is_vegetable precedence that SellerOrderSettlementService uses
     * for live settlements. Returns null when the store has no
     * category flag or no setting value is configured.
     */
    private function resolveVendorGstPercentForStore($storeId): ?float
    {
        return $this->resolveCategoryPercentForStore($storeId, [
            'is_meat'       => 'vendor_gst_chicken_meat',
            'is_food'       => 'vendor_gst_food',
            'is_super_mart' => 'vendor_gst_super_mart',
            'is_vegetable'  => 'vendor_gst_vegetables_fruits',
        ]);
    }

    /**
     * Same resolution pattern as the GST helper, but for the admin's
     * Vendor Commission Configurations.
     */
    private function resolveVendorCommissionPercentForStore($storeId): ?float
    {
        return $this->resolveCategoryPercentForStore($storeId, [
            'is_meat'       => 'vendor_commission_chicken_meat',
            'is_food'       => 'vendor_commission_food',
            'is_super_mart' => 'vendor_commission_super_mart',
            'is_vegetable'  => 'vendor_commission_vegetables_fruits',
        ]);
    }

    /**
     * Shared store-category-flag lookup used by both vendor-GST and
     * vendor-commission resolvers. Falls through the precedence in
     * the order of the $map keys and reads the matching settings row.
     */
    private function resolveCategoryPercentForStore($storeId, array $map): ?float
    {
        if (empty($storeId)) {
            return null;
        }

        $store = Store::find((int) $storeId);
        if (!$store) {
            return null;
        }

        $variable = null;
        foreach ($map as $flag => $settingKey) {
            if (!empty($store->{$flag})) {
                $variable = $settingKey;
                break;
            }
        }

        if (!$variable) {
            return null;
        }

        $value = DB::table('settings')->where('variable', $variable)->value('value');
        if ($value === null || $value === '') {
            return null;
        }

        return (float) $value;
    }
}