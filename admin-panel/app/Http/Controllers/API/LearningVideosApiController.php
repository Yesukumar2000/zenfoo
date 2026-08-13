<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\LearningVideo;
use App\Models\LearningTopic;
use App\Services\MediaUploadService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Auth;
use getID3;

class LearningVideosApiController extends Controller
{
    /**
     * Get all learning videos
     *
     * GET /api/learning_videos
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function index(Request $request)
    {
        try {
            $query = LearningVideo::with('topic');

            // Filter by topic
            if ($request->has('topic_id') && $request->topic_id) {
                $query->where('topic_id', $request->topic_id);
            }

            // Filter by status
            if ($request->has('status') && $request->status !== '') {
                $query->where('status', $request->status);
            }

            // Search by title
            if ($request->has('search') && $request->search) {
                $query->where('title', 'like', '%' . $request->search . '%');
            }

            $videos = $query->orderBy('sort_order', 'asc')
                ->orderBy('created_at', 'desc')
                ->get();

            $formattedVideos = $videos->map(function ($video) {
                return [
                    'id' => $video->id,
                    'topic_id' => $video->topic_id,
                    'topic_name' => $video->topic ? $video->topic->name : null,
                    'title' => $video->title,
                    'description' => $video->description,
                    'video_url' => $video->video_url_full,
                    'video_type' => $video->video_type,
                    'thumbnail' => $video->thumbnail,
                    'thumbnail_url' => $video->thumbnail_url,
                    'duration' => $video->duration,
                    'formatted_duration' => $video->formatted_duration,
                    'sort_order' => $video->sort_order,
                    'status' => $video->status,
                    'created_at' => $video->created_at->toIso8601String(),
                    'updated_at' => $video->updated_at->toIso8601String(),
                ];
            });

            return CommonHelper::responseWithData($formattedVideos, $formattedVideos->count());

        } catch (\Exception $e) {
            Log::error('Failed to get learning videos', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError('Failed to retrieve learning videos');
        }
    }

    /**
     * Create a new learning video
     *
     * POST /api/learning_videos/save
     * Body (multipart/form-data): {
     *   "topic_id": 1,
     *   "title": "Video Title",
     *   "description": "Video description",
     *   "video_type": "upload", // upload, youtube, vimeo
     *   "video": File (video) - for upload type,
     *   "video_url": "URL" - for youtube/vimeo type,
     *   "thumbnail": File (image) - optional,
     *   "duration": 120, // in seconds
     *   "sort_order": 0,
     *   "status": 1
     * }
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function save(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'topic_id' => 'required|exists:learning_topics,id',
                'title' => 'required|string|max:255',
                'description' => 'nullable|string',
                'video_type' => 'required|in:upload,youtube,vimeo',
                'video' => 'required_if:video_type,upload|file|mimes:mp4,mov,avi,wmv,flv,mkv|max:102400', // 100MB max
                'video_url' => 'required_unless:video_type,upload|url',
                'thumbnail' => 'nullable|image|mimes:jpeg,jpg,png,gif|max:5120',
                'duration' => 'nullable|integer|min:0',
                'sort_order' => 'nullable|integer|min:0',
                'status' => 'nullable|in:0,1'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $video = new LearningVideo();
            $video->topic_id = $request->topic_id;
            $video->title = $request->title;
            $video->description = $request->description;
            $video->video_type = $request->video_type;
            $video->sort_order = $request->has('sort_order') ? $request->sort_order : 0;
            $video->status = $request->has('status') ? $request->status : 1;
            $video->created_by = Auth::id();

            // Handle video upload using MediaUploadService
            if ($request->video_type === 'upload' && $request->hasFile('video')) {
                $video->video_url = MediaUploadService::upload(
                    $request->file('video'),
                    'learning/videos'
                );

                // Try to extract video duration
                try {
                    $tempPath = $request->file('video')->getRealPath();
                    $getID3 = new getID3();
                    $fileInfo = $getID3->analyze($tempPath);
                    if (isset($fileInfo['playtime_seconds'])) {
                        $video->duration = (int) $fileInfo['playtime_seconds'];
                    }
                } catch (\Exception $e) {
                    Log::warning('Failed to extract video duration', [
                        'error' => $e->getMessage()
                    ]);
                }
            } else {
                $video->video_url = $request->video_url;
            }

            // Set duration from request if provided
            if ($request->has('duration')) {
                $video->duration = $request->duration;
            }

            // Handle thumbnail upload using MediaUploadService
            if ($request->hasFile('thumbnail')) {
                $video->thumbnail = MediaUploadService::upload(
                    $request->file('thumbnail'),
                    'learning/thumbnails'
                );
            }

            $video->save();

            Log::info('Learning video created', [
                'video_id' => $video->id,
                'topic_id' => $video->topic_id,
                'title' => $video->title,
                'created_by' => Auth::id()
            ]);

            return CommonHelper::responseWithData([
                'video' => [
                    'id' => $video->id,
                    'topic_id' => $video->topic_id,
                    'title' => $video->title,
                    'description' => $video->description,
                    'video_url' => $video->video_url_full,
                    'video_type' => $video->video_type,
                    'thumbnail_url' => $video->thumbnail_url,
                    'duration' => $video->duration,
                    'formatted_duration' => $video->formatted_duration,
                    'sort_order' => $video->sort_order,
                    'status' => $video->status,
                ],
                'message' => 'Learning video created successfully'
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to create learning video', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError('Failed to create learning video: ' . $e->getMessage());
        }
    }

    /**
     * Update an existing learning video
     *
     * POST /api/learning_videos/update
     * Body (multipart/form-data): {
     *   "id": 1,
     *   "topic_id": 1,
     *   "title": "Updated Video Title",
     *   "description": "Updated description",
     *   "video_type": "upload",
     *   "video": File (video) - optional,
     *   "video_url": "URL" - optional,
     *   "thumbnail": File (image) - optional,
     *   "duration": 150,
     *   "sort_order": 1,
     *   "status": 1
     * }
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function update(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'id' => 'required|exists:learning_videos,id',
                'topic_id' => 'required|exists:learning_topics,id',
                'title' => 'required|string|max:255',
                'description' => 'nullable|string',
                'video_type' => 'required|in:upload,youtube,vimeo',
                'video' => 'nullable|file|mimes:mp4,mov,avi,wmv,flv,mkv|max:102400',
                'video_url' => 'nullable|url',
                'thumbnail' => 'nullable|image|mimes:jpeg,jpg,png,gif|max:5120',
                'duration' => 'nullable|integer|min:0',
                'sort_order' => 'nullable|integer|min:0',
                'status' => 'nullable|in:0,1'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $video = LearningVideo::find($request->id);

            if (!$video) {
                return CommonHelper::responseError('Learning video not found!');
            }

            $video->topic_id = $request->topic_id;
            $video->title = $request->title;
            $video->description = $request->description;
            $video->video_type = $request->video_type;
            $video->sort_order = $request->has('sort_order') ? $request->sort_order : $video->sort_order;
            $video->status = $request->has('status') ? $request->status : $video->status;

            // Handle video upload or URL update using MediaUploadService
            if ($request->hasFile('video')) {
                $oldVideoUrl = ($video->video_type === 'upload') ? $video->video_url : null;
                $video->video_url = MediaUploadService::upload(
                    $request->file('video'),
                    'learning/videos',
                    'public',
                    $oldVideoUrl
                );

                // Try to extract video duration
                try {
                    $tempPath = $request->file('video')->getRealPath();
                    $getID3 = new getID3();
                    $fileInfo = $getID3->analyze($tempPath);
                    if (isset($fileInfo['playtime_seconds'])) {
                        $video->duration = (int) $fileInfo['playtime_seconds'];
                    }
                } catch (\Exception $e) {
                    Log::warning('Failed to extract video duration', [
                        'error' => $e->getMessage()
                    ]);
                }
            } elseif ($request->has('video_url') && $request->video_url) {
                $video->video_url = $request->video_url;
            }

            // Set duration from request if provided
            if ($request->has('duration')) {
                $video->duration = $request->duration;
            }

            // Handle thumbnail upload using MediaUploadService
            if ($request->hasFile('thumbnail')) {
                $video->thumbnail = MediaUploadService::upload(
                    $request->file('thumbnail'),
                    'learning/thumbnails',
                    'public',
                    $video->thumbnail
                );
            }

            $video->save();

            Log::info('Learning video updated', [
                'video_id' => $video->id,
                'topic_id' => $video->topic_id,
                'title' => $video->title,
                'updated_by' => Auth::id()
            ]);

            return CommonHelper::responseWithData([
                'video' => [
                    'id' => $video->id,
                    'topic_id' => $video->topic_id,
                    'title' => $video->title,
                    'description' => $video->description,
                    'video_url' => $video->video_url_full,
                    'video_type' => $video->video_type,
                    'thumbnail_url' => $video->thumbnail_url,
                    'duration' => $video->duration,
                    'formatted_duration' => $video->formatted_duration,
                    'sort_order' => $video->sort_order,
                    'status' => $video->status,
                ],
                'message' => 'Learning video updated successfully'
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to update learning video', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError('Failed to update learning video');
        }
    }

    /**
     * Delete a learning video
     *
     * POST /api/learning_videos/delete
     * Body: {
     *   "id": 1
     * }
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function delete(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'id' => 'required|exists:learning_videos,id'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $video = LearningVideo::find($request->id);

            if (!$video) {
                return CommonHelper::responseError('Learning video not found!');
            }

            // Delete associated video file using MediaUploadService
            if ($video->video_url && $video->video_type === 'upload') {
                MediaUploadService::deleteByUrl($video->video_url);
            }

            // Delete thumbnail using MediaUploadService
            if ($video->thumbnail) {
                MediaUploadService::deleteByUrl($video->thumbnail);
            }

            $video->delete();

            Log::info('Learning video deleted', [
                'video_id' => $request->id,
                'deleted_by' => Auth::id()
            ]);

            return CommonHelper::responseWithData([
                'message' => 'Learning video deleted successfully'
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to delete learning video', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError('Failed to delete learning video');
        }
    }

    /**
     * Update video status
     *
     * POST /api/learning_videos/update-status
     * Body: {
     *   "id": 1,
     *   "status": 1
     * }
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function updateStatus(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'id' => 'required|exists:learning_videos,id',
                'status' => 'required|in:0,1'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $video = LearningVideo::find($request->id);

            if (!$video) {
                return CommonHelper::responseError('Learning video not found!');
            }

            $video->status = $request->status;
            $video->save();

            Log::info('Learning video status updated', [
                'video_id' => $video->id,
                'status' => $request->status,
                'updated_by' => Auth::id()
            ]);

            return CommonHelper::responseWithData([
                'message' => 'Video status updated successfully'
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to update video status', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError('Failed to update video status');
        }
    }
}
