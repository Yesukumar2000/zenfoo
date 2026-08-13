<?php

namespace App\Http\Controllers\API\Admin;

use App\Http\Controllers\Controller;
use App\Models\BrandCampaign;
use App\Models\Brand;
use App\Helpers\CommonHelper;
use App\Services\MediaUploadService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class BrandCampaignController extends Controller
{
    /**
     * Get all brand campaigns
     */
    public function index(Request $request)
    {
        try {
            $query = BrandCampaign::with('brand:id,name')->orderBy('created_at', 'desc');

            if ($request->filled('status')) {
                $query->where('status', $request->status);
            }

            if ($request->filled('campaign_type')) {
                $query->where('campaign_type', $request->campaign_type);
            }

            $campaigns = $query->get()->map(function ($campaign) {
                return $this->formatCampaign($campaign);
            });

            return CommonHelper::responseWithData($campaigns);
        } catch (\Exception $e) {
            Log::error('Failed to fetch campaigns', ['error' => $e->getMessage()]);
            return CommonHelper::responseError('Failed to fetch campaigns');
        }
    }

    /**
     * Get single campaign
     */
    public function show($id)
    {
        try {
            $campaign = BrandCampaign::with('brand:id,name')->findOrFail($id);
            return CommonHelper::responseWithData(['campaign' => $this->formatCampaign($campaign)]);
        } catch (\Exception $e) {
            Log::error('Failed to fetch campaign', ['id' => $id, 'error' => $e->getMessage()]);
            return CommonHelper::responseError('Campaign not found');
        }
    }

    /**
     * Create new campaign
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'brand_id' => 'required|exists:brands,id',
            'start_date' => 'required|date',
            'end_date' => 'required|date|after:start_date',
            'status' => 'required|in:0,1',
            'campaign_type' => 'required|in:brand_promotion,seasonal,flash_sale,bundle_offer',
            'theme_color' => 'nullable|string|max:20',
            'primary_image' => 'required|image|mimes:jpg,jpeg,png,gif,webp|max:5120',
            'secondary_image' => 'nullable|image|mimes:jpg,jpeg,png,gif,webp|max:5120',
            'banners' => 'nullable|array',
            'banners.*' => 'file|mimes:jpg,jpeg,png,gif,webp,mp4,webm|max:102400',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        DB::beginTransaction();
        try {
            $data = $request->only([
                'name', 'description', 'brand_id',
                'start_date', 'end_date', 'status',
                'campaign_type', 'theme_color'
            ]);

            // Upload primary image
            if ($request->hasFile('primary_image')) {
                $data['primary_image_url'] = MediaUploadService::upload(
                    $request->file('primary_image'),
                    'campaigns/primary'
                );
            }

            // Upload secondary image
            if ($request->hasFile('secondary_image')) {
                $data['secondary_image_url'] = MediaUploadService::upload(
                    $request->file('secondary_image'),
                    'campaigns/secondary'
                );
            }

            // Upload banners
            if ($request->hasFile('banners')) {
                $banners = [];
                foreach ($request->file('banners') as $file) {
                    // Ensure the file is valid before uploading
                    if ($file && $file->isValid()) {
                        $url = MediaUploadService::upload($file, 'campaigns/banners');
                        $banners[] = [
                            'type' => str_starts_with($file->getMimeType(), 'video/') ? 'video' : 'image',
                            'url' => $url,
                        ];
                    }
                }
                if (!empty($banners)) {
                    $data['banners'] = $banners;
                }
            }

            $campaign = BrandCampaign::create($data);
            DB::commit();

            return CommonHelper::responseWithData([
                'campaign' => $this->formatCampaign($campaign->load('brand:id,name')),
                'message' => 'Campaign created successfully'
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Failed to create campaign', ['error' => $e->getMessage()]);
            return CommonHelper::responseError('Failed to create campaign: ' . $e->getMessage());
        }
    }

    /**
     * Update campaign
     */
    public function update(Request $request, $id)
    {
        $campaign = BrandCampaign::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'name' => 'sometimes|string|max:255',
            'description' => 'nullable|string',
            'tagline' => 'nullable|string|max:500',
            'brand_id' => 'sometimes|exists:brands,id',
            'start_date' => 'sometimes|date',
            'end_date' => 'sometimes|date|after:start_date',
            'status' => 'sometimes|in:0,1',
            'campaign_type' => 'sometimes|in:brand_promotion,seasonal,flash_sale,bundle_offer',
            'theme_color' => 'nullable|string|max:20',
            'primary_image' => 'nullable|image|mimes:jpg,jpeg,png,gif,webp|max:5120',
            'secondary_image' => 'nullable|image|mimes:jpg,jpeg,png,gif,webp|max:5120',
            'existing_banners' => 'nullable|json',
            'banners' => 'nullable|array',
            'banners.*' => 'file|mimes:jpg,jpeg,png,gif,webp,mp4,webm|max:102400',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        DB::beginTransaction();
        try {
            $data = $request->only([
                'name', 'description', 'brand_id',
                'start_date', 'end_date', 'status',
                'campaign_type', 'theme_color'
            ]);

            // Update primary image
            if ($request->hasFile('primary_image')) {
                $data['primary_image_url'] = MediaUploadService::upload(
                    $request->file('primary_image'),
                    'campaigns/primary',
                    'public',
                    $campaign->primary_image_url
                );
            }

            // Update secondary image
            if ($request->hasFile('secondary_image')) {
                $data['secondary_image_url'] = MediaUploadService::upload(
                    $request->file('secondary_image'),
                    'campaigns/secondary',
                    'public',
                    $campaign->secondary_image_url
                );
            }

            // Update banners - merge existing with new
            $banners = [];

            // Keep existing banners if provided
            if ($request->filled('existing_banners')) {
                $existingBanners = json_decode($request->existing_banners, true);
                if (is_array($existingBanners)) {
                    $banners = $existingBanners;
                    Log::info('Keeping existing banners', ['count' => count($existingBanners)]);
                }
            }

            // Add new banners
            if ($request->hasFile('banners')) {
                $uploadedBanners = [];
                foreach ($request->file('banners') as $index => $file) {
                    // Ensure the file is valid before uploading
                    if ($file && $file->isValid()) {
                        Log::info('Uploading new banner', ['index' => $index, 'name' => $file->getClientOriginalName()]);
                        $url = MediaUploadService::upload($file, 'campaigns/banners');
                        $uploadedBanners[] = [
                            'type' => str_starts_with($file->getMimeType(), 'video/') ? 'video' : 'image',
                            'url' => $url,
                        ];
                    } else {
                        Log::warning('Invalid banner file skipped', ['index' => $index]);
                    }
                }
                $banners = array_merge($banners, $uploadedBanners);
                Log::info('Total banners after upload', ['count' => count($banners)]);
            }

            // Only update banners if there are changes
            if (!empty($banners) || $request->has('existing_banners')) {
                $data['banners'] = $banners;
            }

            $campaign->update($data);
            DB::commit();

            return CommonHelper::responseWithData([
                'campaign' => $this->formatCampaign($campaign->fresh()->load('brand:id,name')),
                'message' => 'Campaign updated successfully'
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Failed to update campaign', ['id' => $id, 'error' => $e->getMessage()]);
            return CommonHelper::responseError('Failed to update campaign: ' . $e->getMessage());
        }
    }

    /**
     * Delete campaign
     */
    public function destroy($id)
    {
        try {
            $campaign = BrandCampaign::findOrFail($id);

            // Delete associated files
            if ($campaign->primary_image_url) {
                Storage::disk('public')->delete($campaign->primary_image_url);
            }
            if ($campaign->secondary_image_url) {
                Storage::disk('public')->delete($campaign->secondary_image_url);
            }
            if ($campaign->banners) {
                foreach ($campaign->banners as $banner) {
                    if (!empty($banner['url'])) {
                        Storage::disk('public')->delete($banner['url']);
                    }
                }
            }

            $campaign->delete();

            return CommonHelper::responseWithData(['message' => 'Campaign deleted successfully']);
        } catch (\Exception $e) {
            Log::error('Failed to delete campaign', ['id' => $id, 'error' => $e->getMessage()]);
            return CommonHelper::responseError('Failed to delete campaign');
        }
    }

    /**
     * Format campaign for response
     */
    private function formatCampaign($campaign): array
    {
        return [
            'id' => $campaign->id,
            'name' => $campaign->name,
            'description' => $campaign->description,
            'primary_image_url' => $campaign->primary_image_url,
            'secondary_image_url' => $campaign->secondary_image_url,
            'banners' => $campaign->banners ?? [],
            'brand_id' => $campaign->brand_id,
            'brand_name' => $campaign->brand->name ?? null,
            'products_count' => $campaign->products()->count(),
            'campaign_type' => $campaign->campaign_type,
            'theme_color' => $campaign->theme_color,
            'start_date' => $campaign->start_date?->format('Y-m-d H:i:s'),
            'end_date' => $campaign->end_date?->format('Y-m-d H:i:s'),
            'status' => $campaign->status,
            'is_active' => $campaign->isActive(),
            'is_expired' => $campaign->isExpired(),
            'created_at' => $campaign->created_at?->format('Y-m-d H:i:s'),
            'updated_at' => $campaign->updated_at?->format('Y-m-d H:i:s'),
        ];
    }
}