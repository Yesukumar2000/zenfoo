<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Combo;
use App\Models\Product;
use App\Models\SpecialItem;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class SpecialItemController extends Controller
{
    // Fetch all combos (for listing)
    public function getSpecialItem(Request $request)
    {
        $specialItem = SpecialItem::orderBy('id', 'desc')->get(); 
        // $categoryIds = explode(',', $specialItem->category_ids);

        // $categories = Category::whereIn('id', $categoryIds)->get();
        return response()->json($specialItem);
    }

    // Fetch all products for creating a new combo
    public function getProductsForCombo()
    {
        $products = Product::all()->map(function($p) {
            $p->image_url = $p->image ? (str_starts_with($p->image, 'http') ? $p->image : asset('storage/' . $p->image)) : asset('images/no-image.png');
            return $p;
        });

        return response()->json(['products' => $products]);
    }

    // Fetch combo for editing (combo + all products)
    public function edit($id)
    {
        $combo = Combo::with('products')->findOrFail($id);
        $allProducts = Product::all()->map(function($p) {
            $p->image_url = $p->image ? (str_starts_with($p->image, 'http') ? $p->image : asset('storage/' . $p->image)) : asset('images/no-image.png');
            return $p;
        });

        // Attach quantities to products
        $quantities = $combo->products->pluck('pivot.quantity', 'id');

        $allProducts->transform(function($p) use ($quantities) {
            $p->quantity = $quantities[$p->id] ?? 0;
            return $p;
        });

        return response()->json([
            'combo' => $combo,
            'products' => $allProducts
        ]);
    }

    // Save or update combo
    public function save(Request $request)
    {
        $request->validate([
            'title' => 'required|string',
            'category_ids' => 'required|array',
        ]);

        $specialItem = SpecialItem::create([
            'title' => $request->title,
            'category_ids' => implode(',', $request->category_ids),
        ]);

        return response()->json([
            'status' => 1,
            'message' => 'Special item saved successfully',
            'data' => $specialItem
        ]);
    }
    // Delete combo
    public function destroy(Request $request)
    {
        $combo = Combo::findOrFail($request->id);

        if ($combo->image) {
            Storage::disk('public')->delete($combo->image);
        }

        $combo->delete();

        return response()->json(['status' => 1, 'message' => 'Combo deleted successfully']);
    }

    // Change combo status
    public function changeStatus(Request $request)
    {
        $combo = Combo::findOrFail($request->id);
        $combo->status = $request->status;
        $combo->save();

        return response()->json(['status' => 1, 'message' => 'Status updated']);
    }
}
