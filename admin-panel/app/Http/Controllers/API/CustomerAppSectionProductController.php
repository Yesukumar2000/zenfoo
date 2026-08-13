<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\CustomerAppSectionProduct;
use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class CustomerAppSectionProductController extends Controller
{
    public function list(Request $request)
    {
        $limit = $request->input('per_page', 10);
        $offset = (($request->input('page', 0)) - 1) * $limit;
        $filter = $request->input('filter', '');
        $sectionId = $request->input('section_id');

        $query = CustomerAppSectionProduct::with(['product.category:id,name', 'section'])
            ->orderBy('display_order', 'asc')
            ->orderBy('id', 'DESC');

        if ($filter) {
            $query->whereHas('product', function($q) use ($filter) {
                $q->where('name', 'like', "%{$filter}%");
            });
        }

        if ($sectionId) {
            $query->where('section_id', $sectionId);
        }

        $total = $query->count();
        $sectionProducts = $query->skip($offset)->take($limit)->get()->map(function ($sp) {
            $imageUrl = null;
            if ($sp->product && $sp->product->image) {
                $imageUrl = $sp->product->image;
                if (!str_starts_with($imageUrl, 'http')) {
                    $imageUrl = url('storage/' . $imageUrl);
                }
            }

            return [
                'id' => $sp->id,
                'product_id' => $sp->product_id,
                'product_name' => $sp->product->name ?? null,
                'product_image' => $sp->product->image ?? null,
                'product_image_url' => $imageUrl,
                'category_name' => $sp->product->category->name ?? null,
                'section_id' => $sp->section_id,
                'section_name' => $sp->section->name ?? null,
                'display_order' => $sp->display_order,
                'product' => $sp->product,
                'section' => $sp->section,
                'created_at' => $sp->created_at?->format('Y-m-d H:i:s'),
            ];
        });

        return CommonHelper::responseWithData($sectionProducts, $total);
    }

    public function save(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'product_id' => 'required|exists:products,id',
            'section_id' => 'required|exists:customer_app_sections,id',
            'display_order' => 'nullable|integer|min:0',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        // Check if this combination already exists
        $exists = CustomerAppSectionProduct::where('product_id', $request->product_id)
            ->where('section_id', $request->section_id)
            ->exists();

        if ($exists) {
            return CommonHelper::responseError("This product is already added to this section!");
        }

        // Get next display order if not provided
        $displayOrder = $request->display_order ?? CustomerAppSectionProduct::where('section_id', $request->section_id)->max('display_order') + 1;

        $sectionProduct = new CustomerAppSectionProduct();
        $sectionProduct->product_id = $request->product_id;
        $sectionProduct->section_id = $request->section_id;
        $sectionProduct->display_order = $displayOrder;
        $sectionProduct->save();

        return CommonHelper::responseSuccess("Product added to section successfully!");
    }

    public function update(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'id' => 'required|exists:customer_app_section_products,id',
            'product_id' => 'required|exists:products,id',
            'section_id' => 'required|exists:customer_app_sections,id',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        // Check if this combination already exists (excluding current record)
        $exists = CustomerAppSectionProduct::where('product_id', $request->product_id)
            ->where('section_id', $request->section_id)
            ->where('id', '!=', $request->id)
            ->exists();

        if ($exists) {
            return CommonHelper::responseError("This product is already added to this section!");
        }

        if (isset($request->id)) {
            $sectionProduct = CustomerAppSectionProduct::find($request->id);
            $sectionProduct->product_id = $request->product_id;
            $sectionProduct->section_id = $request->section_id;
            $sectionProduct->save();
        }

        return CommonHelper::responseSuccess("Product updated successfully!");
    }

    public function delete(Request $request)
    {
        if (isset($request->id)) {
            $sectionProduct = CustomerAppSectionProduct::find($request->id);

            if ($sectionProduct) {
                $sectionProduct->delete();
                return CommonHelper::responseSuccess("Product removed from section successfully!");
            } else {
                return CommonHelper::responseSuccess("Product already deleted!");
            }
        }
    }

    public function show(Request $request, $id)
    {
        $sectionProduct = CustomerAppSectionProduct::with(['product', 'section'])->find($id);

        if (!$sectionProduct) {
            return CommonHelper::responseError("Record not found!");
        }

        return CommonHelper::responseWithData($sectionProduct);
    }

    /**
     * Reorder section products
     */
    public function reorder(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'items' => 'required|array|min:1',
            'items.*.id' => 'required|exists:customer_app_section_products,id',
            'items.*.display_order' => 'required|integer|min:0',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        DB::beginTransaction();
        try {
            foreach ($request->items as $item) {
                CustomerAppSectionProduct::where('id', $item['id'])
                    ->update(['display_order' => $item['display_order']]);
            }

            DB::commit();
            return CommonHelper::responseSuccess('Products reordered successfully!');

        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Failed to reorder section products', ['error' => $e->getMessage()]);
            return CommonHelper::responseError('Failed to reorder products');
        }
    }

    /**
     * Delete all products from a section
     */
    public function deleteAll($sectionId)
    {
        try {
            // Delete all products for this section
            CustomerAppSectionProduct::where('section_id', $sectionId)->delete();

            return CommonHelper::responseSuccess('All products removed from section successfully!');
        } catch (\Exception $e) {
            Log::error('Failed to delete all section products', ['section_id' => $sectionId, 'error' => $e->getMessage()]);
            return CommonHelper::responseError('Failed to remove products from section');
        }
    }
}