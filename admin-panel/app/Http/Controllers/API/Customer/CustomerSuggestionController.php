<?php

namespace App\Http\Controllers\API\Customer;

use App\Http\Controllers\Controller;
use App\Models\CustomerSuggestion;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class CustomerSuggestionController extends Controller
{
    /**
     * Store a customer suggestion
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function store(Request $request)
    {
        try {
            // Validate the request
            $validator = Validator::make($request->all(), [
                'suggestion' => 'required|string|min:5|max:5000',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors()
                ], 422);
            }

            // Get authenticated customer
            $customer = auth('api-customers')->user();

            // Create the suggestion
            $suggestion = CustomerSuggestion::create([
                'customer_id' => $customer->id,
                'suggestion' => $request->suggestion,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Thank you for your suggestion! We appreciate your feedback.',
            ], 201);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to submit suggestion. Please try again.',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get customer's suggestions
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function index(Request $request)
    {
        try {
            $customer = auth('api-customers')->user();

            $suggestions = CustomerSuggestion::where('customer_id', $customer->id)
                ->orderBy('created_at', 'desc')
                ->paginate(10);

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
}
