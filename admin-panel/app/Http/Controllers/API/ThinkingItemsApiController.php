<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\Setting;
use App\Models\ThinkingItem;
use App\Models\Category;
use App\Models\CategorySubGroup;
use App\Models\Product;
use App\Services\MediaUploadService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class ThinkingItemsApiController extends Controller
{
    /**
     * Get all thinking items with category details
     */
    public function index()
    {
        $thinkingItems = ThinkingItem::with('category:id,name,image')
            ->orderBy('id', 'DESC')
            ->get();

        return CommonHelper::responseWithData($thinkingItems);
    }

    /**
     * Get unique categories from products with store_id = 15
     */
    public function getCategories()
    {
        // Get unique category IDs from products with store_id = 15
        $categoryIds = Product::where('store_id', 15)
            ->where('status', 1)
            ->distinct()
            ->pluck('category_id')
            ->filter()
            ->toArray();

        // Get category details
        $categories = Category::whereIn('id', $categoryIds)
            ->where('status', 1)
            ->orderBy('name', 'ASC')
            ->get(['id', 'name', 'image']);

        return CommonHelper::responseWithData($categories);
    }

    /**
     * Get active thinking items for customer app
     * Returns only items with status = 1
     */
    public function getForCustomer()
    {
        $thinkingItems = ThinkingItem::with('category:id,name,image')
            ->where('status', 1)
            ->orderBy('id', 'DESC')
            ->get();

        // Add category group information to each item
        $thinkingItems = $thinkingItems->map(function ($item) {
            if ($item->category) {
                // Find the CategorySubGroup that contains this category_id in subcategory_ids
                $subCategoryGroup = CategorySubGroup::whereRaw(
                    "FIND_IN_SET(?, subcategory_ids) > 0",
                    [$item->category_id]
                )->with('categoryGroup:id,name')->first();

                if ($subCategoryGroup && $subCategoryGroup->categoryGroup) {
                    $item->category_group = [
                        'id' => $subCategoryGroup->categoryGroup->id,
                        'name' => $subCategoryGroup->categoryGroup->name
                    ];
                } else {
                    $item->category_group = null;
                }
            } else {
                $item->category_group = null;
            }

            return $item;
        });

        return CommonHelper::responseWithData($thinkingItems);
    }

    /**
     * Get the "What are you thinking?" title from settings
     * Public API - no auth required
     */
    public function getTitle()
    {
        $title = Setting::get_value('what_are_you_thinking');

        return CommonHelper::responseWithData([
            'title' => $title ?: "what's your taste today?"
        ]);
    }

    /**
     * Get a single thinking item by ID
     */
    public function show($id)
    {
        $thinkingItem = ThinkingItem::with('category:id,name,image')->find($id);

        if (!$thinkingItem) {
            return CommonHelper::responseError("Thinking item not found");
        }

        return CommonHelper::responseWithData($thinkingItem);
    }

    /**
     * Save a new thinking item
     */
    public function save(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'category_id' => 'required|exists:categories,id',
            'image' => 'required|image|mimes:jpeg,png,jpg,gif|max:2048',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        // Get category details
        $category = Category::find($request->category_id);

        if (!$category) {
            return CommonHelper::responseError("Category not found");
        }

        $thinkingItem = new ThinkingItem();
        $thinkingItem->name = $category->name; // Use category name
        $thinkingItem->category_id = $request->category_id;
        $thinkingItem->status = 1; // Active by default

        // Upload image
        if ($request->hasFile('image')) {
            $thinkingItem->img_url = MediaUploadService::upload(
                $request->file('image'),
                'thinking_items'
            );
        }

        $thinkingItem->save();

        return CommonHelper::responseSuccess("Thinking item saved successfully!");
    }

    /**
     * Update an existing thinking item
     */
    public function update(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'id' => 'required|exists:thinking_items,id',
            'category_id' => 'required|exists:categories,id',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $thinkingItem = ThinkingItem::find($request->id);

        if (!$thinkingItem) {
            return CommonHelper::responseError("Thinking item not found");
        }

        // Get category details
        $category = Category::find($request->category_id);

        if (!$category) {
            return CommonHelper::responseError("Category not found");
        }

        $thinkingItem->name = $category->name; // Update name from category
        $thinkingItem->category_id = $request->category_id;

        // Upload new image if provided
        if ($request->hasFile('image')) {
            $thinkingItem->img_url = MediaUploadService::upload(
                $request->file('image'),
                'thinking_items'
            );
        }

        $thinkingItem->save();

        return CommonHelper::responseSuccess("Thinking item updated successfully!");
    }

    /**
     * Toggle status (active/inactive)
     */
    public function toggleStatus(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'id' => 'required|exists:thinking_items,id',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $thinkingItem = ThinkingItem::find($request->id);

        if (!$thinkingItem) {
            return CommonHelper::responseError("Thinking item not found");
        }

        // Toggle status: 1 to 0 or 0 to 1
        $thinkingItem->status = $thinkingItem->status == 1 ? 0 : 1;
        $thinkingItem->save();

        $statusText = $thinkingItem->status == 1 ? 'activated' : 'deactivated';

        return CommonHelper::responseSuccess("Thinking item {$statusText} successfully!");
    }

    /**
     * Delete a thinking item
     */
    public function delete($id)
    {
        $thinkingItem = ThinkingItem::find($id);

        if (!$thinkingItem) {
            return CommonHelper::responseError("Thinking item not found");
        }

        $thinkingItem->delete();

        return CommonHelper::responseSuccess("Thinking item deleted successfully!");
    }
}
