<?php

namespace App\Http\Controllers\API\Admin;

use App\Http\Controllers\Controller;
use App\Models\CustomerSuggestion;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class CustomerSuggestionController extends Controller
{
    /**
     * Get all customer suggestions for admin
     *
     * @return \Illuminate\Http\JsonResponse
     */
    public function index()
    {
        try {
            $suggestions = CustomerSuggestion::with('customer:id,name,mobile,email')
                ->orderBy('created_at', 'desc')
                ->get();

            return response()->json([
                'success' => true,
                'data' => $suggestions
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve suggestions',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Respond to a customer suggestion
     *
     * @param Request $request
     * @param int $id
     * @return \Illuminate\Http\JsonResponse
     */
    public function respond(Request $request, $id)
    {
        try {
            $validator = Validator::make($request->all(), [
                'admin_response' => 'required|string|min:5|max:5000',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors()
                ], 422);
            }

            $suggestion = CustomerSuggestion::findOrFail($id);

            $suggestion->update([
                'admin_response' => $request->admin_response,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Response saved successfully',
                'data' => $suggestion
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to save response',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}