<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\CustomerAppSection;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class CustomerAppSectionController extends Controller
{
    public function list(Request $request)
    {
        $limit = $request->input('per_page', 10); // Default items per page
        $offset = (($request->input('page', 0)) - 1) * $limit; // Default page
        $filter = $request->input('filter', ''); // Filter query

        // Fetch paginated data
        $sections = CustomerAppSection::orderBy('order', 'ASC');

        if ($filter) {
            $sections = $sections->where(function($query) use ($filter) {
                $query->where('name', 'like', "%{$filter}%");
            });
        }

        $total = $sections->count();
        $sections = $sections->skip($offset)->take($limit)->get();

        return CommonHelper::responseWithData($sections, $total);
    }

    public function save(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'order' => 'nullable|integer',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $section = new CustomerAppSection();
        $section->name = $request->name;
        $section->order = $request->order ?? 0;
        $section->save();

        return CommonHelper::responseSuccess("Section Saved Successfully!");
    }

    public function update(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'id' => 'required|exists:customer_app_sections,id',
            'name' => 'required|string|max:255',
            'order' => 'nullable|integer',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        if (isset($request->id)) {
            $section = CustomerAppSection::find($request->id);
            $section->name = $request->name;
            $section->order = $request->order ?? 0;
            $section->save();
        }

        return CommonHelper::responseSuccess("Section Updated Successfully!");
    }

    public function delete(Request $request)
    {
        if (isset($request->id)) {
            $section = CustomerAppSection::find($request->id);

            if ($section) {
                $section->delete();
                return CommonHelper::responseSuccess("Section Deleted Successfully!");
            } else {
                return CommonHelper::responseSuccess("Section Already Deleted!");
            }
        }
    }

    public function show(Request $request, $id)
    {
        $section = CustomerAppSection::find($id);

        if (!$section) {
            return CommonHelper::responseError("Section not found!");
        }

        return CommonHelper::responseWithData($section);
    }

    public function getSectionsByRowOrder(Request $request)
    {
        $sections = CustomerAppSection::orderBy('order', 'ASC')->get();
        return CommonHelper::responseWithData($sections);
    }

    public function updateSectionsOrder(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'sections' => 'required|array',
            'sections.*.id' => 'required|exists:customer_app_sections,id',
            'sections.*.row_order' => 'required|integer',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        try {
            foreach ($request->sections as $sectionData) {
                $section = CustomerAppSection::find($sectionData['id']);
                if ($section) {
                    $section->order = $sectionData['row_order'];
                    $section->save();
                }
            }

            return CommonHelper::responseSuccess("Section order updated successfully!");
        } catch (\Exception $e) {
            return CommonHelper::responseError("Failed to update section order: " . $e->getMessage());
        }
    }
}