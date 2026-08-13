<?php

namespace App\Services;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Config;
use Exception;

class MediaUploadService
{
    private static bool $s3Configured = false;
    private static ?string $resolvedDriver = null;

    /**
     * Read storage_driver from settings. Returns 's3' (default) or 'local'.
     * Cached per-request.
     */
    private static function getStorageDriver(): string
    {
        if (self::$resolvedDriver !== null) {
            return self::$resolvedDriver;
        }

        try {
            $value = DB::table('settings')->where('variable', 'storage_driver')->value('value');
        } catch (Exception $e) {
            $value = null;
        }

        self::$resolvedDriver = ($value === 'local') ? 'local' : 's3';
        return self::$resolvedDriver;
    }

    /**
     * Resolve the Laravel disk name to use for current upload/delete based
     * on the storage_driver setting. Configures S3 lazily when needed.
     */
    private static function resolveDisk(): string
    {
        if (self::getStorageDriver() === 'local') {
            return 'public';
        }

        self::configureS3();
        return 's3';
    }

    /**
     * Configure S3 disk at runtime using values from the settings table
     */
    private static function configureS3(): void
    {
        if (self::$s3Configured) {
            return;
        }

        $awsSettings = DB::table('settings')
            ->whereIn('variable', ['aws_access_key_id', 'aws_secret_access_key', 'aws_default_region', 'aws_bucket'])
            ->pluck('value', 'variable');

        $key = $awsSettings['aws_access_key_id'] ?? '';
        $secret = $awsSettings['aws_secret_access_key'] ?? '';
        $region = $awsSettings['aws_default_region'] ?? 'us-east-1';
        $bucket = $awsSettings['aws_bucket'] ?? '';

        if (empty($key) || empty($secret) || empty($bucket)) {
            throw new Exception('AWS S3 credentials are not configured. Please set them in Store Settings.');
        }

        Config::set('filesystems.disks.s3.key', $key);
        Config::set('filesystems.disks.s3.secret', $secret);
        Config::set('filesystems.disks.s3.region', $region);
        Config::set('filesystems.disks.s3.bucket', $bucket);

        // Purge the resolved S3 disk so it picks up new config
        Storage::forgetDisk('s3');

        // On localhost, rebuild S3 disk with SSL verification disabled
        if (app()->environment('local')) {
            $s3Client = new \Aws\S3\S3Client([
                'version' => 'latest',
                'region' => $region,
                'credentials' => [
                    'key' => $key,
                    'secret' => $secret,
                ],
                'http' => ['verify' => false],
            ]);

            $adapter = new \League\Flysystem\AwsS3v3\AwsS3Adapter($s3Client, $bucket);
            $filesystem = new \League\Flysystem\Filesystem($adapter);

            Storage::set('s3', new \Illuminate\Filesystem\FilesystemAdapter($filesystem, $adapter));
        }

        self::$s3Configured = true;
    }

    /**
     * Upload image or video and return full URL.
     * Uses S3 or local disk based on storage_driver setting.
     */
    public static function upload(
        UploadedFile $file,
        string $folder = 'uploads',
        string $disk = 's3',
        ?string $oldFile = null
    ): string {
        $disk = self::resolveDisk();

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

        // Delete old file if provided
        if ($oldFile) {
            self::deleteByUrl($oldFile, $disk);
        }

        // Generate name and upload
        $fileName = time() . '_' . uniqid() . '.' . $file->getClientOriginalExtension();
        $path = Storage::disk($disk)->putFileAs($folder, $file, $fileName);

        // Return full URL
        return Storage::disk($disk)->url($path);
    }

    /**
     * Upload image or video and return full URL.
     * Uses S3 or local disk based on storage_driver setting.
     */
    public static function uploadWithFullUrl(
        UploadedFile $file,
        string $folder = 'uploads',
        string $disk = 's3',
        ?string $oldFile = null
    ): string {
        $disk = self::resolveDisk();

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

        // Delete old file if provided
        if ($oldFile) {
            self::deleteByUrl($oldFile, $disk);
        }

        // Generate name and upload
        $fileName = time() . '_' . uniqid() . '.' . $file->getClientOriginalExtension();
        $path = Storage::disk($disk)->putFileAs($folder, $file, $fileName);

        // Return full URL
        return Storage::disk($disk)->url($path);
    }

    /**
     * Upload message attachment (images, PDF, DOC files) and return full URL.
     * Uses S3 or local disk based on storage_driver setting.
     */
    public static function uploadMessageAttachment(
        UploadedFile $file,
        string $folder = 'messages',
        string $disk = 's3',
        ?string $oldFile = null
    ): string {
        $disk = self::resolveDisk();

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

        // Return full URL
        return Storage::disk($disk)->url($path);
    }

    /**
     * Delete a file by its full URL. Routes to S3 or local disk based on the URL.
     */
    public static function deleteByUrl(string $url, string $disk = 's3'): bool
    {
        if (empty($url)) {
            return false;
        }

        // Pick the disk that the URL actually belongs to (rather than the current
        // toggle setting), so old S3 files can still be cleaned up after switching.
        $diskForUrl = self::diskForUrl($url);

        try {
            if ($diskForUrl === 's3') {
                self::configureS3();
            }
        } catch (Exception $e) {
            return false;
        }

        $path = self::getPathFromUrl($url);

        if ($path && Storage::disk($diskForUrl)->exists($path)) {
            return Storage::disk($diskForUrl)->delete($path);
        }
        return false;
    }

    /**
     * Alias for deleteByUrl (used in some controllers)
     */
    public static function deleteFileByUrl(string $url, string $disk = 's3'): bool
    {
        return self::deleteByUrl($url, $disk);
    }

    /**
     * Delete a file by path (legacy support).
     * Uses the currently active disk per storage_driver setting.
     */
    public static function deleteFile(string $path, string $disk = 's3'): bool
    {
        try {
            $disk = self::resolveDisk();
        } catch (Exception $e) {
            return false;
        }

        if ($path && Storage::disk($disk)->exists($path)) {
            return Storage::disk($disk)->delete($path);
        }
        return false;
    }

    /**
     * Get full URL from a storage path using the currently active disk.
     */
    public static function getFullUrl(string $path, string $disk = 's3'): string
    {
        if (empty($path)) {
            return '';
        }

        // If already a full URL, return as-is
        if (str_starts_with($path, 'http')) {
            return $path;
        }

        try {
            $disk = self::resolveDisk();
        } catch (Exception $e) {
            return $path;
        }

        return Storage::disk($disk)->url($path);
    }

    /**
     * Decide whether a stored URL belongs to S3 or the local public disk,
     * so legacy URLs continue to resolve correctly after toggling drivers.
     */
    private static function diskForUrl(string $url): string
    {
        if (str_contains($url, 'amazonaws.com') || str_contains($url, 's3.')) {
            return 's3';
        }
        if (str_contains($url, '/storage/')) {
            return 'public';
        }
        // Fallback to whatever is currently configured.
        return self::getStorageDriver() === 'local' ? 'public' : 's3';
    }

    /**
     * Extract the storage path from a full URL
     */
    public static function getPathFromUrl(string $url): string
    {
        if (empty($url)) {
            return '';
        }

        // If it's not a URL, assume it's already a path
        if (!str_starts_with($url, 'http')) {
            return ltrim($url, '/');
        }

        $parsed = parse_url($url);
        if (!isset($parsed['path'])) {
            return '';
        }

        $path = ltrim($parsed['path'], '/');

        // Local public disk URLs look like /storage/uploads/foo.jpg
        if (str_starts_with($path, 'storage/')) {
            return substr($path, strlen('storage/'));
        }

        // S3 path-style URL: https://s3.region.amazonaws.com/bucket/folder/file.jpg
        $bucket = config('filesystems.disks.s3.bucket');
        if ($bucket && str_starts_with($path, $bucket . '/')) {
            $path = substr($path, strlen($bucket) + 1);
        }

        return $path;
    }
}
