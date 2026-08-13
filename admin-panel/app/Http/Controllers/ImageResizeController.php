<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Intervention\Image\ImageManager;
use Intervention\Image\Drivers\Gd\Driver;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Cache;

class ImageResizeController extends Controller
{
    /**
     * Resize image on-the-fly
     * URL format: /resize/{width}x{height}/{path}
     * Example: /resize/300x300/storage/categories/image.jpg
     */
    public function resize($dimensions, Request $request)
    {
        // Parse dimensions
        [$width, $height] = explode('x', $dimensions);
        $width = (int) $width;
        $height = (int) $height;

        // Validate dimensions (max 2000x2000 to prevent abuse)
        if ($width > 2000 || $height > 2000 || $width < 1 || $height < 1) {
            abort(400, 'Invalid dimensions');
        }

        // Get the image path from the remaining URL segments
        $path = $request->path();
        // Remove 'resize/{dimensions}/' from the path
        $imagePath = preg_replace('#^resize/' . preg_quote($dimensions, '#') . '/#', '', $path);

        // Create cache key
        $cacheKey = 'resized_image_' . md5($imagePath . '_' . $dimensions);

        // Check if resized image is cached
        if (Cache::has($cacheKey)) {
            $cachedData = Cache::get($cacheKey);
            return response($cachedData['content'])
                ->header('Content-Type', $cachedData['mime'])
                ->header('Cache-Control', 'public, max-age=31536000'); // Cache for 1 year
        }

        // Check if image exists in public folder or remote URL
        $fullPath = public_path($imagePath);
        $isRemote = false;

        if (!file_exists($fullPath)) {
            // Try to construct full URL from the path
            $fullUrl = url($imagePath);

            // Check if the URL is accessible
            $headers = @get_headers($fullUrl);
            if ($headers && strpos($headers[0], '200') !== false) {
                $isRemote = true;
                $fullPath = $fullUrl;
            } else {
                abort(404, 'Image not found');
            }
        }

        try {
            // Create image manager with GD driver
            $manager = new ImageManager(new Driver());

            // Read and resize image (works with both local paths and URLs)
            $image = $manager->read($fullPath);

            // Resize image maintaining aspect ratio and fit into dimensions
            $image->cover($width, $height);

            // Encode image
            $encoded = $image->encode();

            // Get mime type
            $mimeType = mime_content_type($fullPath) ?: 'image/jpeg';

            // Cache the resized image for 7 days
            Cache::put($cacheKey, [
                'content' => $encoded,
                'mime' => $mimeType
            ], now()->addDays(7));

            return response($encoded)
                ->header('Content-Type', $mimeType)
                ->header('Cache-Control', 'public, max-age=31536000'); // Cache for 1 year

        } catch (\Exception $e) {
            abort(500, 'Error processing image: ' . $e->getMessage());
        }
    }
}
