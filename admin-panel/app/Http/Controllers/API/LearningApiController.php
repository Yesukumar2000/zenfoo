<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\LearningTopic;
use App\Models\LearningVideo;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class LearningApiController extends Controller
{
    /**
     * Get all active learning topics for app
     *
     * GET /api/learning/topics
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getTopics(Request $request)
    {
        try {
            $topics = LearningTopic::active()
                ->ordered()
                ->get();

            $formattedTopics = $topics->map(function ($topic) {
                return [
                    'id' => $topic->id,
                    'name' => $topic->name,
                    'description' => $topic->description,
                    'image_url' => $topic->image_url,
                    'videos_count' => $topic->activeVideos()->count(),
                ];
            });

            return CommonHelper::responseWithData($formattedTopics, $formattedTopics->count());

        } catch (\Exception $e) {
            Log::error('Failed to get learning topics for app', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError('Failed to retrieve learning topics');
        }
    }

    /**
     * Get topic details with videos
     *
     * GET /api/learning/topic/{id}
     *
     * @param int $id
     * @return \Illuminate\Http\JsonResponse
     */
    public function getTopicDetails($id)
    {
        try {
            $topic = LearningTopic::active()
                ->with(['activeVideos' => function ($query) {
                    $query->orderBy('sort_order', 'asc');
                }])
                ->find($id);

            if (!$topic) {
                return CommonHelper::responseError('Learning topic not found!');
            }

            $videos = $topic->activeVideos->map(function ($video) {
                return [
                    'id' => $video->id,
                    'title' => $video->title,
                    'description' => $video->description,
                    'video_url' => $video->video_url_full,
                    'video_type' => $video->video_type,
                    'thumbnail_url' => $video->thumbnail_url,
                    'duration' => $video->duration,
                    'formatted_duration' => $video->formatted_duration,
                ];
            });

            $topicData = [
                'id' => $topic->id,
                'name' => $topic->name,
                'description' => $topic->description,
                'image_url' => $topic->image_url,
                'videos_count' => $videos->count(),
                'videos' => $videos,
            ];

            return CommonHelper::responseWithData($topicData);

        } catch (\Exception $e) {
            Log::error('Failed to get topic details for app', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'topic_id' => $id
            ]);
            return CommonHelper::responseError('Failed to retrieve topic details');
        }
    }

    /**
     * Get all videos across all topics (optional filtering by topic)
     *
     * GET /api/learning/videos
     * Query Parameters:
     *   - topic_id (optional): Filter by specific topic
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getVideos(Request $request)
    {
        try {
            $query = LearningVideo::active()
                ->with('topic')
                ->ordered();

            if ($request->has('topic_id') && $request->topic_id) {
                $query->where('topic_id', $request->topic_id);
            }

            $videos = $query->get();

            $formattedVideos = $videos->map(function ($video) {
                return [
                    'id' => $video->id,
                    'topic_id' => $video->topic_id,
                    'topic_name' => $video->topic ? $video->topic->name : null,
                    'title' => $video->title,
                    'description' => $video->description,
                    'video_url' => $video->video_url_full,
                    'video_type' => $video->video_type,
                    'thumbnail_url' => $video->thumbnail_url,
                    'duration' => $video->duration,
                    'formatted_duration' => $video->formatted_duration,
                ];
            });

            return CommonHelper::responseWithData($formattedVideos, $formattedVideos->count());

        } catch (\Exception $e) {
            Log::error('Failed to get learning videos for app', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError('Failed to retrieve learning videos');
        }
    }

    /**
     * Get single video details
     *
     * GET /api/learning/video/{id}
     *
     * @param int $id
     * @return \Illuminate\Http\JsonResponse
     */
    public function getVideoDetails($id)
    {
        try {
            $video = LearningVideo::active()
                ->with('topic')
                ->find($id);

            if (!$video) {
                return CommonHelper::responseError('Learning video not found!');
            }

            $videoData = [
                'id' => $video->id,
                'topic_id' => $video->topic_id,
                'topic_name' => $video->topic ? $video->topic->name : null,
                'title' => $video->title,
                'description' => $video->description,
                'video_url' => $video->video_url_full,
                'video_type' => $video->video_type,
                'thumbnail_url' => $video->thumbnail_url,
                'duration' => $video->duration,
                'formatted_duration' => $video->formatted_duration,
            ];

            return CommonHelper::responseWithData($videoData);

        } catch (\Exception $e) {
            Log::error('Failed to get video details for app', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'video_id' => $id
            ]);
            return CommonHelper::responseError('Failed to retrieve video details');
        }
    }
}
