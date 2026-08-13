<?php

namespace App\Services;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Exception;

class MediaUploadServiceNormal
{
    /**
     * Upload image or video and return full URL
     * This method returns the full URL to be stored in database
     * When switching to AWS S3, only this method needs to be updated
     */
    public static function upload(
        UploadedFile $file,
        string $folder = 'uploads',
        string $disk = 'public',
        ?string $oldFile = null
    ): string {
        // Max limits
        $maxImageSize = 5 * 1024 * 1024;   // 5MB
        $maxVideoSize = 100 * 1024 * 1024;  // 100MB for videos

        $mime = $file->getMimeType();
        $size = $file->getSize();

        // Allowed types
        $imageTypes = ['image/jpeg', 'image/png', 'image/jpg', 'image/gif', 'image/webp', 'image/svg+xml'];
        $videoTypes = ['video/mp4', 'video/webm', 'video/ogg', 'video/avi', 'video/mov', 'video/wmv', 'video/flv', 'video/mkv'];

        if (in_array($mime, $imageTypes)) {
            if ($size > $maxImageSize) {
                throw new Exception("Image size must be less than 5MB");
            }
        }
        elseif (in_array($mime, $videoTypes)) {
            if ($size > $maxVideoSize) {
                throw new Exception("Video size must be less than 100MB");
            }
        }
        else {
            throw new Exception("Invalid image or video file type");
        }

        // Delete old file if provided (extract path from URL first)
        if ($oldFile) {
            self::deleteByUrl($oldFile, $disk);
        }

        // Generate name and upload
        $fileName = time() . '_' . uniqid() . '.' . $file->getClientOriginalExtension();
        $path = Storage::disk($disk)->putFileAs($folder, $file, $fileName);

        // Return full URL with APP_URL (when switching to AWS, change this to return S3 URL)
        $url = Storage::disk($disk)->url($path);

        // Ensure full URL with domain
        if (!str_starts_with($url, 'http')) {
            $appUrl = config('app.url') ?: request()->getSchemeAndHttpHost();
            $url = rtrim($appUrl, '/') . '/' . ltrim($url, '/');
        }

        return $url;
    }

        /**
     * Upload image or video and return full URL
     * This method returns the full URL to be stored in database
     * When switching to AWS S3, only this method needs to be updated
     */
    public static function uploadWithFullUrl(
        UploadedFile $file,
        string $folder = 'uploads',
        string $disk = 'public',
        ?string $oldFile = null
    ): string {
        // Max limits
        $maxImageSize = 5 * 1024 * 1024;   // 5MB
        $maxVideoSize = 100 * 1024 * 1024;  // 100MB for videos

        $mime = $file->getMimeType();
        $size = $file->getSize();

        // Allowed types
        $imageTypes = ['image/jpeg', 'image/png', 'image/jpg', 'image/gif', 'image/webp', 'image/svg+xml'];
        $videoTypes = ['video/mp4', 'video/webm', 'video/ogg', 'video/avi', 'video/mov', 'video/wmv', 'video/flv', 'video/mkv'];

        if (in_array($mime, $imageTypes)) {
            if ($size > $maxImageSize) {
                throw new Exception("Image size must be less than 5MB");
            }
        }
        elseif (in_array($mime, $videoTypes)) {
            if ($size > $maxVideoSize) {
                throw new Exception("Video size must be less than 100MB");
            }
        }
        else {
            throw new Exception("Invalid image or video file type");
        }

        // Delete old file if provided (extract path from URL first)
        if ($oldFile) {
            self::deleteByUrl($oldFile, $disk);
        }

        // Generate name and upload
        $fileName = time() . '_' . uniqid() . '.' . $file->getClientOriginalExtension();
        $path = Storage::disk($disk)->putFileAs($folder, $file, $fileName);

        // Return full URL with APP_URL (when switching to AWS, change this to return S3 URL)
        $url = Storage::disk($disk)->url($path);

        // Ensure full URL with domain
        if (!str_starts_with($url, 'http')) {
            $appUrl = config('app.url') ?: request()->getSchemeAndHttpHost();
            $url = rtrim($appUrl, '/') . '/' . ltrim($url, '/');
        }

        return $url;
    }

    /**
     * Upload message attachment (images, PDF, DOC files) and return full URL
     */
    public static function uploadMessageAttachment(
        UploadedFile $file,
        string $folder = 'messages',
        string $disk = 'public',
        ?string $oldFile = null
    ): string {
        // Max limits
        $maxImageSize = 5 * 1024 * 1024;   // 5MB
        $maxDocSize = 10 * 1024 * 1024;    // 10MB for documents

        $mime = $file->getMimeType();
        $size = $file->getSize();

        // Allowed types
        $imageTypes = ['image/jpeg', 'image/png', 'image/jpg', 'image/gif', 'image/webp'];
        $documentTypes = [
            'application/pdf',
            'application/msword',
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            'application/vnd.ms-excel',
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'text/plain'
        ];

        if (in_array($mime, $imageTypes)) {
            if ($size > $maxImageSize) {
                throw new Exception("Image size must be less than 5MB");
            }
        } elseif (in_array($mime, $documentTypes)) {
            if ($size > $maxDocSize) {
                throw new Exception("Document size must be less than 10MB");
            }
        } else {
            throw new Exception("Invalid file type. Allowed: images, PDF, DOC, DOCX, XLS, XLSX, TXT");
        }

        // Delete old file if provided
        if ($oldFile) {
            self::deleteByUrl($oldFile, $disk);
        }

        // Generate name and upload
        $fileName = time() . '_' . uniqid() . '.' . $file->getClientOriginalExtension();
        $path = Storage::disk($disk)->putFileAs($folder, $file, $fileName);

        // Return full URL with APP_URL
        $url = Storage::disk($disk)->url($path);

        // Ensure full URL with domain
        if (!str_starts_with($url, 'http')) {
            $appUrl = config('app.url') ?: request()->getSchemeAndHttpHost();
            $url = rtrim($appUrl, '/') . '/' . ltrim($url, '/');
        }

        return $url;
    }

    /**
     * Delete a file from storage by URL
     */
    public static function deleteByUrl(string $url, string $disk = 'public'): bool
    {
        if (empty($url)) {
            return false;
        }

        // Extract path from URL
        // For local storage: http://localhost/storage/path/file.jpg -> path/file.jpg
        // For AWS S3: https://bucket.s3.region.amazonaws.com/path/file.jpg -> path/file.jpg

        $baseUrl = Storage::disk($disk)->url('');
        $path = str_replace($baseUrl, '', $url);
        $path = ltrim($path, '/');

        if ($path && Storage::disk($disk)->exists($path)) {
            return Storage::disk($disk)->delete($path);
        }
        return false;
    }

    /**
     * Delete a file from storage by path (legacy support)
     */
    public static function deleteFile(string $path, string $disk = 'public'): bool
    {
        if ($path && Storage::disk($disk)->exists($path)) {
            return Storage::disk($disk)->delete($path);
        }
        return false;
    }
}
