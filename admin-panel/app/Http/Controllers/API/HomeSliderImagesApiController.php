<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Setting;
use App\Models\Store;
use App\Models\Tax;
use App\Models\Slider;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use App\Services\MediaUploadService;
use App\Models\SubCategoryGroup;

class HomeSliderImagesApiController extends Controller
{
    public function index(){

        $sliders = Slider::with('category','product')->orderBy('id','DESC')->get();

        return CommonHelper::responseWithData($sliders);
    }

    // public function save(Request $request){
    //     $validator = Validator::make($request->all(),[
    //         'type' => 'required',
    //         'type_id' => 'required_if:type,category,product',
    //         'slider_url' => 'required_if:type,==,slider_url',
    //         'image' => 'required|mimes:jpeg,jpg,png,gif'
    //     ],[
    //         'type_id.required_if' => 'The '.$request->type.' field is required when type is '.$request->type.'.',
    //         'slider_url.required_if' => 'The link field is required when type is Slider Url.',
    //         'slider_url.url' => 'The link must be a valid URL.',
    //     ]);

    //     if ($validator->fails()) {
    //         return CommonHelper::responseError($validator->errors()->first());
    //     }

    //     $slider = new Slider();
    //     $slider->type = $request->type;
    //     $slider->type_id = ($request->type_id)?$request->type_id:0;
    //     $image = '';
    //     if($request->hasFile('image')){
    //         $file = $request->file('image');
    //         $fileName = time().'_'.rand(1111,99999).'.'.$file->getClientOriginalExtension();
    //         $image = Storage::disk('public')->putFileAs('sliders', $file, $fileName);
    //     }
    //    $slider->image = $image;
    //    $slider->slider_url = $request->slider_url;
    //    $slider->save();
    //    return CommonHelper::responseSuccess("Home Slider Images Saved Successfully!");
    // }

    // public function update(Request $request){
    //     $validator = Validator::make($request->all(),[
    //         'type' => 'required',
    //         'type_id' => 'required_if:type,category,product',
    //         'slider_url' => 'required_if:type,==,slider_url',
    //         'image' => $request->hasFile('image') ? 'mimes:jpeg,jpg,png,gif' : ''
    //     ],[
    //         'type_id.required_if' => 'The '.$request->type.' field is required when type is '.$request->type.'.',
    //         'slider_url.required_if' => 'The link field is required when type is Slider Url.',
    //         'slider_url.url' => 'The link must be a valid URL.',
    //     ]);

    //     if ($validator->fails()) {
    //         return CommonHelper::responseError($validator->errors()->first());
    //     }

    //     if(isset($request->id)){

    //         $slider = Slider::find($request->id);
    //         $slider->type = $request->type;
    //         $slider->type_id = $request->type_id;
    //         $slider->status = $request->status;
    //         if($request->hasFile('image')){
    //             @Storage::disk('public')->delete($slider->image);
    //             $file = $request->file('image');
    //             $fileName = time().'_'.rand(1111,99999).'.'.$file->getClientOriginalExtension();
    //             $image = Storage::disk('public')->putFileAs('sliders', $file, $fileName);
    //             $slider->image = $image;
    //         }
    //         $slider->slider_url = $request->slider_url;
    //         $slider->save();
    //     }


    //     return CommonHelper::responseSuccess("Slider Updated Successfully!");
    // }


    public function save(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'type'       => 'required|in:default,category,product,store,slider_url,promotional,seller,driver,driver_login,order_page',
            'type_id'    => 'required_if:type,category,product',
            'slider_url' => 'nullable',
            'media'      => 'required|file',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $slider = new Slider();
        $slider->type                 = $request->type;
        $slider->type_id              = $request->type_id ?? 0;
        $slider->status               = 1;
        $slider->slider_url           = $request->slider_url;
        $slider->store_id             = $request->store_id ?? null;
        $slider->category_group_id    = $request->category_group_id ?? null;
        $slider->sub_category_group_id = $request->sub_category_group_id ?? null;
        $slider->slider_category_id   = $request->slider_category_id ?? null;

        // ✅ SERVICE UPLOAD
        if ($request->hasFile('media')) {
            try {
                $slider->image = MediaUploadService::upload(
                    $request->file('media'),
                    'sliders'
                );
            } catch (\Exception $e) {
                return CommonHelper::responseError($e->getMessage());
            }
        }

        $slider->save();
        return CommonHelper::responseSuccess("Home Slider Media Saved Successfully!");
    }


    public function update(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'id'         => 'required|exists:sliders,id',
            'type'       => 'required|in:default,category,product,store,slider_url,promotional,seller,driver,driver_login,order_page',
            'type_id'    => 'required_if:type,category,product',
            'slider_url' => 'nullable',
            'media'      => 'nullable|file',
            'status'     => 'required|in:0,1'
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $slider = Slider::find($request->id);
        $slider->type                 = $request->type;
        $slider->type_id              = $request->type_id ?? 0;
        $slider->status               = $request->status;
        $slider->slider_url           = $request->slider_url;
        $slider->store_id             = $request->store_id ?? null;
        $slider->category_group_id    = $request->category_group_id ?? null;
        $slider->sub_category_group_id = $request->sub_category_group_id ?? null;
        $slider->slider_category_id   = $request->slider_category_id ?? null;

        // ✅ SERVICE UPLOAD WITH DELETE
        if ($request->hasFile('media')) {
            try {
                $slider->image = MediaUploadService::upload(
                    $request->file('media'),
                    'sliders',
                    's3',
                    $slider->image
                );
            } catch (\Exception $e) {
                return CommonHelper::responseError($e->getMessage());
            }
        }

        $slider->save();

        return CommonHelper::responseSuccess("Slider Updated Successfully!");
    }

    public function delete(Request $request){

        if(isset($request->id)){

            $slider = Slider::find($request->id);
            if($slider){
                @Storage::disk('public')->delete($slider->image);
                $slider->delete();
                return CommonHelper::responseSuccess("Slider Deleted Successfully!");
            }else{
                return CommonHelper::responseSuccess("Slider Already Deleted!");
            }
        }
    }

    /**
     * Get promotional banners only
     */
    public function getPromotionalBanners()
    {
        $banners = Slider::select('id', 'store_id', 'type', 'type_id', 'image', 'slider_url', 'status', 'created_at', 'updated_at')
            ->where('type', 'order_page')
            ->where('status', 1)
            ->orderBy('id', 'DESC')
            ->get();

        return CommonHelper::responseWithData($banners);
    }

    /**
     * Get App Launch Banner
     */
    public function getAppLaunchBanner(Request $request)
    {
        $url = Setting::get_value('app_launch_banner');
        $color = Setting::get_value('app_launch_banner_color');
        $imgWidth = Setting::get_value('app_launch_banner_img_width');
        $imgHeight = Setting::get_value('app_launch_banner_img_height');
        $orientation = Setting::get_value('app_launch_banner_orientation');
        $ratio = Setting::get_value('app_launch_banner_ratio');

        // Get special items with pagination
        $perPage = $request->get('per_page', 6);
        $page = $request->get('page', 1);

        $specialItems = SubCategoryGroup::where('is_special_item', 1)
            ->select('id', 'name', 'image')
            ->paginate($perPage, ['*'], 'page', $page);

        $specialItemsData = $specialItems->getCollection()->map(function ($item) {
            return [
                'id' => $item->id,
                'name' => $item->name,
                'image_url' => $item->image_url,
            ];
        });

        return response()->json([
            'status' => 1,
            'url' => $url ?: null,
            'color' => $color ?: '#FFFFFF',
            'img_width' => $imgWidth ? (int)$imgWidth : 0,
            'img_height' => $imgHeight ? (int)$imgHeight : 0,
            'orientation' => in_array($orientation, ['portrait', 'landscape']) ? $orientation : 'portrait',
            'ratio' => $ratio ?: (in_array($orientation, ['landscape']) ? '16:9' : '9:16'),
            'special_items' => [
                'data' => $specialItemsData,
                'pagination' => [
                    'current_page' => $specialItems->currentPage(),
                    'last_page' => $specialItems->lastPage(),
                    'per_page' => $specialItems->perPage(),
                    'total' => $specialItems->total(),
                ],
            ],
        ], 200);
    }

    /**
     * Update App Launch Banner
     */
    public function updateAppLaunchBanner(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'image' => 'nullable|mimes:jpeg,jpg,png,gif,webp,mp4,mov,avi,webm',
            'color' => 'nullable|string|max:20',
            'orientation' => 'nullable|in:portrait,landscape',
            'ratio' => 'nullable|regex:/^\d{1,3}:\d{1,3}$/',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        try {
            $fullUrl = Setting::get_value('app_launch_banner');

            // Handle image upload if provided
            if ($request->hasFile('image')) {
                // Get image dimensions before upload
                $imageFile = $request->file('image');
                $imageDimensions = getimagesize($imageFile->getPathname());
                $imgWidth = $imageDimensions ? $imageDimensions[0] : 0;
                $imgHeight = $imageDimensions ? $imageDimensions[1] : 0;

                // Get old banner path for deletion
                $oldBannerUrl = Setting::get_value('app_launch_banner');
                $oldPath = null;
                if ($oldBannerUrl) {
                    // Extract path from full URL
                    $oldPath = str_replace(asset('storage/'), '', $oldBannerUrl);
                }

                // Upload new image - MediaUploadService already returns full URL
                $fullUrl = MediaUploadService::upload(
                    $imageFile,
                    'app_launch_banner',
                    'public',
                    $oldPath ?: null
                );

                // Update or create setting with full URL
                $setting = Setting::where('variable', 'app_launch_banner')->first();
                if ($setting) {
                    $setting->value = $fullUrl;
                    $setting->save();
                } else {
                    $setting = new Setting();
                    $setting->variable = 'app_launch_banner';
                    $setting->value = $fullUrl;
                    $setting->save();
                }

                // Update or create width setting
                $widthSetting = Setting::where('variable', 'app_launch_banner_img_width')->first();
                if ($widthSetting) {
                    $widthSetting->value = $imgWidth;
                    $widthSetting->save();
                } else {
                    $widthSetting = new Setting();
                    $widthSetting->variable = 'app_launch_banner_img_width';
                    $widthSetting->value = $imgWidth;
                    $widthSetting->save();
                }

                // Update or create height setting
                $heightSetting = Setting::where('variable', 'app_launch_banner_img_height')->first();
                if ($heightSetting) {
                    $heightSetting->value = $imgHeight;
                    $heightSetting->save();
                } else {
                    $heightSetting = new Setting();
                    $heightSetting->variable = 'app_launch_banner_img_height';
                    $heightSetting->value = $imgHeight;
                    $heightSetting->save();
                }
            }

            // Handle color update if provided
            $color = $request->color;
            if ($color) {
                $colorSetting = Setting::where('variable', 'app_launch_banner_color')->first();
                if ($colorSetting) {
                    $colorSetting->value = $color;
                    $colorSetting->save();
                } else {
                    $colorSetting = new Setting();
                    $colorSetting->variable = 'app_launch_banner_color';
                    $colorSetting->value = $color;
                    $colorSetting->save();
                }
            }

            // Handle orientation update if provided
            $orientation = $request->orientation;
            if ($orientation) {
                $orientationSetting = Setting::where('variable', 'app_launch_banner_orientation')->first();
                if ($orientationSetting) {
                    $orientationSetting->value = $orientation;
                    $orientationSetting->save();
                } else {
                    $orientationSetting = new Setting();
                    $orientationSetting->variable = 'app_launch_banner_orientation';
                    $orientationSetting->value = $orientation;
                    $orientationSetting->save();
                }
            }

            // Handle ratio update if provided
            $ratio = $request->ratio;
            if ($ratio) {
                $ratioSetting = Setting::where('variable', 'app_launch_banner_ratio')->first();
                if ($ratioSetting) {
                    $ratioSetting->value = $ratio;
                    $ratioSetting->save();
                } else {
                    $ratioSetting = new Setting();
                    $ratioSetting->variable = 'app_launch_banner_ratio';
                    $ratioSetting->value = $ratio;
                    $ratioSetting->save();
                }
            }

            $resolvedOrientation = $orientation ?: (Setting::get_value('app_launch_banner_orientation') ?: 'portrait');

            return response()->json([
                'status' => 1,
                'url' => $fullUrl ?: null,
                'color' => $color ?: Setting::get_value('app_launch_banner_color') ?: '#FFFFFF',
                'img_width' => Setting::get_value('app_launch_banner_img_width') ?: 0,
                'img_height' => Setting::get_value('app_launch_banner_img_height') ?: 0,
                'orientation' => $resolvedOrientation,
                'ratio' => $ratio ?: (Setting::get_value('app_launch_banner_ratio') ?: ($resolvedOrientation === 'landscape' ? '16:9' : '9:16')),
            ], 200);

        } catch (\Exception $e) {
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Get Special Items (sub_category_groups where is_special_item = 1)
     */
    public function getSpecialItems()
    {
        $specialItems = SubCategoryGroup::where('is_special_item', 1)
            ->select('id', 'name', 'image', 'category_group_id')
            ->with(['categoryGroup:id,name', 'categoryGroup.stores:id,name'])
            ->get();

        $data = $specialItems->map(function ($item) {
            $store = $item->categoryGroup && $item->categoryGroup->stores->first()
                ? $item->categoryGroup->stores->first()
                : null;

            return [
                'id' => $item->id,
                'name' => $item->name,
                'image_url' => $item->image_url,
                'store_id' => $store ? $store->id : null,
                'store_name' => $store ? $store->name : 'Unknown',
                'category_group_id' => $item->category_group_id,
                'category_group_name' => $item->categoryGroup->name ?? 'Unknown',
            ];
        });

        return response()->json([
            'status' => 1,
            'data' => $data,
        ], 200);
    }

    /**
     * Update Special Items
     */
    public function updateSpecialItems(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'special_item_ids' => 'nullable|array',
            'special_item_ids.*' => 'integer|exists:sub_category_groups,id',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        try {
            $newSpecialItemIds = $request->special_item_ids ?? [];

            // Reset all existing special items to 0
            SubCategoryGroup::where('is_special_item', 1)->update(['is_special_item' => 0]);

            // Set new special items to 1
            if (!empty($newSpecialItemIds)) {
                SubCategoryGroup::whereIn('id', $newSpecialItemIds)->update(['is_special_item' => 1]);
            }

            return response()->json([
                'status' => 1,
                'message' => 'Special items updated successfully!',
            ], 200);

        } catch (\Exception $e) {
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Get public banners for seller app — only type=category and type=store, active only, no auth required
     */
    public function getPublicBanners()
    {
        $banners = Slider::where('type', 'store')
            ->where('status', 1)
            ->orderBy('id', 'DESC')
            ->get();

        $storeIds = $banners->pluck('type_id')->unique();
        $stores   = Store::whereIn('id', $storeIds)->get()->keyBy('id');

        $data = $banners->map(function ($banner) use ($stores) {
            return [
                'id'               => $banner->id,
                'type'             => $banner->type,
                'type_id'          => $banner->type_id,
                'store_name'       => $stores->get($banner->type_id)->name ?? null,
                'image_url'        => $banner->image_url,
                'slider_url'       => $banner->slider_url,
                'android_deeplink' => $banner->android_deeplink,
                'ios_deeplink'     => $banner->ios_deeplink,
            ];
        });

        return CommonHelper::responseWithData($data);
    }

    /**
     * Get banners by type — GET /home_slider_images/by_type?type=seller
     */
    public function getByType(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'type' => 'required|in:default,category,product,store,slider_url,promotional,seller,driver,driver_login,order_page',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $banners = Slider::select('id', 'store_id', 'type', 'type_id', 'image', 'slider_url', 'status', 'created_at', 'updated_at')
            ->where('type', $request->type)
            ->where('status', 1)
            ->orderBy('id', 'DESC')
            ->get();

        return CommonHelper::responseWithData($banners);
    }

    /**
     * Get Special Items for Customer App (with pagination)
     */
    public function getSpecialItemsForCustomer(Request $request)
    {
        $perPage = $request->get('per_page', 6);
        $page = $request->get('page', 1);

        $specialItems = SubCategoryGroup::where('is_special_item', 1)
            ->select('id', 'name', 'image')
            ->paginate($perPage, ['*'], 'page', $page);

        $data = $specialItems->getCollection()->map(function ($item) {
            return [
                'id' => $item->id,
                'name' => $item->name,
                'image_url' => $item->image_url,
            ];
        });

        return response()->json([
            'status' => 1,
            'data' => $data,
            'pagination' => [
                'current_page' => $specialItems->currentPage(),
                'last_page' => $specialItems->lastPage(),
                'per_page' => $specialItems->perPage(),
                'total' => $specialItems->total(),
            ],
        ], 200);
    }

}
