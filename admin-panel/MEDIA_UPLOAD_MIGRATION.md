# Media Upload Service Migration

## Summary
Updated the entire application to use `MediaUploadService` for all file uploads. This centralizes media handling and makes it easy to switch to AWS S3 in the future by only updating the service class.

## Changes Made

### 1. MediaUploadService Updates
**File:** `app/Services/MediaUploadService.php`

**Key Changes:**
- `upload()` method now returns **full URL** instead of path
- Increased video size limit to 100MB (from 20MB)
- Added support for more video formats (wmv, flv, mkv)
- Added `svg+xml` to image types
- Updated `deleteByUrl()` to handle both local and AWS S3 URLs
- Old file deletion now uses URL-based deletion

**Future Migration to AWS:**
When switching to AWS S3, you only need to update these methods in `MediaUploadService`:
1. Change `$disk = 'public'` to `$disk = 's3'` in method signatures
2. Update `Storage::disk($disk)->url($path)` to return S3 URL
3. No controller changes needed!

### 2. Model Updates
**Files:** All models in `app/Models/`

**Changes:**
- Removed `asset()` helper from all image/video URL accessors
- Models now return URLs directly from database
- This allows storing full URLs (local or AWS S3) in database

**Examples:**
```php
// Before
public function getImageUrlAttribute() {
    return asset('storage/' . $this->image);
}

// After
public function getImageUrlAttribute() {
    return $this->image;
}
```

**Updated Models:**
- Vehicle.php
- LearningTopic.php
- LearningVideo.php
- DeliveryBoy.php
- Store.php
- Product.php
- User.php
- And 22 other models

### 3. Learning Controllers Updates

#### LearningTopicsApiController
**File:** `app/Http/Controllers/API/LearningTopicsApiController.php`

**Changes:**
- Added `use App\Services\MediaUploadService`
- **Create:** Use `MediaUploadService::upload()` for image upload
- **Update:** Use `MediaUploadService::upload()` with old URL for deletion
- **Delete:** Use `MediaUploadService::deleteByUrl()` for cleanup

**Before:**
```php
$imagePath = $image->store('learning/topics', 'public');
$topic->image = $imagePath;
```

**After:**
```php
$topic->image = MediaUploadService::upload(
    $request->file('image'),
    'learning/topics'
);
```

#### LearningVideosApiController
**File:** `app/Http/Controllers/API/LearningVideosApiController.php`

**Changes:**
- Added `use App\Services\MediaUploadService`
- **Video Upload:** Use `MediaUploadService::upload()` for videos (stores full URL)
- **Thumbnail Upload:** Use `MediaUploadService::upload()` for thumbnails
- **Duration Extraction:** Use temporary file path with `getRealPath()` instead of storage path
- **Update:** Automatically deletes old files when uploading new ones
- **Delete:** Use `MediaUploadService::deleteByUrl()` for cleanup

**Before:**
```php
$videoPath = $videoFile->store('learning/videos', 'public');
$video->video_url = $videoPath;
$fileInfo = $getID3->analyze(storage_path('app/public/' . $videoPath));
```

**After:**
```php
$video->video_url = MediaUploadService::upload(
    $request->file('video'),
    'learning/videos'
);
$tempPath = $request->file('video')->getRealPath();
$fileInfo = $getID3->analyze($tempPath);
```

## Database Schema

**No migration needed!** The columns still store strings, but now they store full URLs instead of paths:

**Before (Local Path):**
```
learning/topics/1704276845_abc123.jpg
```

**After (Full URL - Local):**
```
http://localhost/storage/learning/topics/1704276845_abc123.jpg
```

**Future (Full URL - AWS S3):**
```
https://your-bucket.s3.region.amazonaws.com/learning/topics/1704276845_abc123.jpg
```

## Benefits

1. **Centralized Logic:** All file upload logic in one service
2. **Easy AWS Migration:** Only update `MediaUploadService`, no controller changes
3. **Consistent URLs:** Full URLs stored in database work for both local and cloud storage
4. **Automatic Cleanup:** Old files deleted automatically when updating
5. **Type Safety:** Validation for file types and sizes in one place
6. **Future-Proof:** Can switch storage providers without touching controllers

## Testing Checklist

- [ ] Test topic image upload (create)
- [ ] Test topic image update (update with new image)
- [ ] Test topic deletion (verify image deleted from storage)
- [ ] Test video upload (create with uploaded video)
- [ ] Test video with YouTube URL
- [ ] Test video thumbnail upload
- [ ] Test video update (verify old files deleted)
- [ ] Test video deletion (verify files deleted from storage)
- [ ] Verify all URLs are accessible
- [ ] Verify file cleanup works correctly

## Next Steps

When ready to migrate to AWS S3:

1. Update `.env` with AWS credentials:
```env
AWS_ACCESS_KEY_ID=your-key
AWS_SECRET_ACCESS_KEY=your-secret
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=your-bucket-name
AWS_URL=https://your-bucket.s3.region.amazonaws.com
```

2. Update `MediaUploadService::upload()`:
```php
// Change default disk from 'public' to 's3'
public static function upload(
    UploadedFile $file,
    string $folder = 'uploads',
    string $disk = 's3',  // Changed from 'public'
    ?string $oldFile = null
): string {
    // ... rest stays the same
}
```

3. That's it! All controllers will automatically use S3.

## Files Modified

### Services
- `app/Services/MediaUploadService.php` ✅

### Controllers (17 files)
- `app/Http/Controllers/API/LearningTopicsApiController.php` ✅
- `app/Http/Controllers/API/LearningVideosApiController.php` ✅
- `app/Http/Controllers/API/Admin/DeliveryBoyAdminController.php` ✅
- `app/Http/Controllers/API/DeliveryBoy/DocumentController.php` ✅
- `app/Http/Controllers/API/StoreController.php` ✅
- `app/Http/Controllers/API/BrandsApiController.php` ✅
- `app/Http/Controllers/API/CategoryApiController.php` ✅
- `app/Http/Controllers/API/OffersApiController.php` ✅
- `app/Http/Controllers/API/PromoCodeApiController.php` ✅
- `app/Http/Controllers/API/SubCategoryGroupController.php` ✅
- `app/Http/Controllers/API/SubCategoryApiController.php` ✅
- `app/Http/Controllers/API/CategoryGroupController.php` ✅
- `app/Http/Controllers/API/SectionsApiController.php` ✅
- `app/Http/Controllers/API/WebSettingsApiController.php` ✅
- `app/Http/Controllers/API/NotificationsApiController.php` ✅
- `app/Http/Controllers/API/PopupApiController.php` ✅
- `app/Http/Controllers/API/ProductApisController.php` ✅

### Helpers
- `app/Helpers/CommonHelper.php` ✅ (uploadProductImages method)

### Models (29 files)
- `app/Models/Vehicle.php` ✅
- `app/Models/LearningTopic.php` ✅
- `app/Models/LearningVideo.php` ✅
- `app/Models/DeliveryBoy.php` ✅
- And 25 other models ✅

### Documentation
- `API_DOCUMENTATION.md` (previously created)
- `MEDIA_UPLOAD_MIGRATION.md` (this file)
