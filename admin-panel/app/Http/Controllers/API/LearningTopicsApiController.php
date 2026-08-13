<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\LearningTopic;
use App\Services\MediaUploadService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Auth;

class LearningTopicsApiController extends Controller
{
    /**
     * Get all learning topics
     *
     * GET /api/learning_topics
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function index(Request $request)
    {
        try {
            $query = LearningTopic::with('videos');

            // Filter by status if provided
            if ($request->has('status') && $request->status !== '') {
                $query->where('status', $request->status);
            }

            // Search by name
            if ($request->has('search') && $request->search) {
                $query->where('name', 'like', '%' . $request->search . '%');
            }

            $topics = $query->orderBy('sort_order', 'asc')
                ->orderBy('created_at', 'desc')
                ->get();

            $formattedTopics = $topics->map(function ($topic) {
                return [
                    'id' => $topic->id,
                    'name' => $topic->name,
                    'description' => $topic->description,
                    'image' => $topic->image,
                    'image_url' => $topic->image_url,
                    'sort_order' => $topic->sort_order,
                    'status' => $topic->status,
                    'videos_count' => $topic->videos_count,
                    'created_at' => $topic->created_at->toIso8601String(),
                    'updated_at' => $topic->updated_at->toIso8601String(),
                ];
            });

            return CommonHelper::responseWithData($formattedTopics, $formattedTopics->count());

        } catch (\Exception $e) {
            Log::error('Failed to get learning topics', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError('Failed to retrieve learning topics');
        }
    }

    /**
     * Create a new learning topic
     *
     * POST /api/learning_topics/save
     * Body (multipart/form-data): {
     *   "name": "Topic Name",
     *   "description": "Topic description",
     *   "image": File (image),
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
                'name' => 'required|string|max:255',
                'description' => 'nullable|string',
                'image' => 'nullable|image|mimes:jpeg,jpg,png,gif,svg|max:5120',
                'sort_order' => 'nullable|integer|min:0',
                'status' => 'nullable|in:0,1'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $topic = new LearningTopic();
            $topic->name = $request->name;
            $topic->description = $request->description;
            $topic->sort_order = $request->has('sort_order') ? $request->sort_order : 0;
            $topic->status = $request->has('status') ? $request->status : 1;
            $topic->created_by = Auth::id();

            // Handle image upload using MediaUploadService (returns full URL)
            if ($request->hasFile('image')) {
                $topic->image = MediaUploadService::upload(
                    $request->file('image'),
                    'learning/topics'
                );
            }

            $topic->save();

            Log::info('Learning topic created', [
                'topic_id' => $topic->id,
                'name' => $topic->name,
                'created_by' => Auth::id()
            ]);

            return CommonHelper::responseWithData([
                'topic' => [
                    'id' => $topic->id,
                    'name' => $topic->name,
                    'description' => $topic->description,
                    'image_url' => $topic->image_url,
                    'sort_order' => $topic->sort_order,
                    'status' => $topic->status,
                ],
                'message' => 'Learning topic created successfully'
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to create learning topic', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError('Failed to create learning topic');
        }
    }

    /**
     * Update an existing learning topic
     *
     * POST /api/learning_topics/update
     * Body (multipart/form-data): {
     *   "id": 1,
     *   "name": "Updated Topic Name",
     *   "description": "Updated description",
     *   "image": File (image) - optional,
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
                'id' => 'required|exists:learning_topics,id',
                'name' => 'required|string|max:255',
                'description' => 'nullable|string',
                'image' => 'nullable|image|mimes:jpeg,jpg,png,gif,svg|max:5120',
                'sort_order' => 'nullable|integer|min:0',
                'status' => 'nullable|in:0,1'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $topic = LearningTopic::find($request->id);

            if (!$topic) {
                return CommonHelper::responseError('Learning topic not found!');
            }

            $topic->name = $request->name;
            $topic->description = $request->description;
            $topic->sort_order = $request->has('sort_order') ? $request->sort_order : $topic->sort_order;
            $topic->status = $request->has('status') ? $request->status : $topic->status;

            // Handle image upload using MediaUploadService
            if ($request->hasFile('image')) {
                $topic->image = MediaUploadService::upload(
                    $request->file('image'),
                    'learning/topics',
                    'public',
                    $topic->image // Pass old URL for deletion
                );
            }

            $topic->save();

            Log::info('Learning topic updated', [
                'topic_id' => $topic->id,
                'name' => $topic->name,
                'updated_by' => Auth::id()
            ]);

            return CommonHelper::responseWithData([
                'topic' => [
                    'id' => $topic->id,
                    'name' => $topic->name,
                    'description' => $topic->description,
                    'image_url' => $topic->image_url,
                    'sort_order' => $topic->sort_order,
                    'status' => $topic->status,
                ],
                'message' => 'Learning topic updated successfully'
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to update learning topic', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError('Failed to update learning topic');
        }
    }

    /**
     * Delete a learning topic
     *
     * POST /api/learning_topics/delete
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
                'id' => 'required|exists:learning_topics,id'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $topic = LearningTopic::find($request->id);

            if (!$topic) {
                return CommonHelper::responseError('Learning topic not found!');
            }

            // Delete associated image using MediaUploadService
            if ($topic->image) {
                MediaUploadService::deleteByUrl($topic->image);
            }

            // Delete all videos associated with this topic (cascade will handle this)
            $topic->delete();

            Log::info('Learning topic deleted', [
                'topic_id' => $request->id,
                'deleted_by' => Auth::id()
            ]);

            return CommonHelper::responseWithData([
                'message' => 'Learning topic deleted successfully'
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to delete learning topic', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError('Failed to delete learning topic');
        }
    }

    /**
     * Update topic status
     *
     * POST /api/learning_topics/update-status
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
                'id' => 'required|exists:learning_topics,id',
                'status' => 'required|in:0,1'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $topic = LearningTopic::find($request->id);

            if (!$topic) {
                return CommonHelper::responseError('Learning topic not found!');
            }

            $topic->status = $request->status;
            $topic->save();

            Log::info('Learning topic status updated', [
                'topic_id' => $topic->id,
                'status' => $request->status,
                'updated_by' => Auth::id()
            ]);

            return CommonHelper::responseWithData([
                'message' => 'Topic status updated successfully'
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to update topic status', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError('Failed to update topic status');
        }
    }
}
