<?php

namespace App\Http\Controllers\API\Admin;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\DriverDutyIssue;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class DriverDutyIssueAdminController extends Controller
{
    /**
     * Get all driver duty issues with filters
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function index(Request $request)
    {
        try {
            $query = DriverDutyIssue::with(['deliveryBoy', 'deliveryBoy.city'])
                ->orderBy('id', 'desc');

            // Filter by type
            if ($request->has('type') && $request->type != '') {
                $query->where('type', $request->type);
            }

            // Filter by status (pending/responded)
            if ($request->has('status') && $request->status != '') {
                if ($request->status === 'pending') {
                    $query->whereNull('admin_response');
                } elseif ($request->status === 'responded') {
                    $query->whereNotNull('admin_response');
                }
            }

            $issues = $query->get();

            return CommonHelper::responseWithData($issues);

        } catch (Exception $e) {
            Log::error("Get Driver Duty Issues Error: ", [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError('Failed to fetch driver duty issues.');
        }
    }

    /**
     * Respond to a driver duty issue
     *
     * @param Request $request
     * @param int $id
     * @return \Illuminate\Http\JsonResponse
     */
    public function respond(Request $request, $id)
    {
        try {
            // Validate request
            $validator = Validator::make($request->all(), [
                'admin_response' => 'required|string',
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            // Find the issue
            $issue = DriverDutyIssue::find($id);

            if (!$issue) {
                return CommonHelper::responseError('Issue not found.');
            }

            // Update the admin response
            $issue->admin_response = $request->admin_response;
            $issue->save();

            return CommonHelper::responseSuccess('Response submitted successfully.');

        } catch (Exception $e) {
            Log::error("Respond to Driver Duty Issue Error: ", [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError('Failed to submit response.');
        }
    }

    /**
     * Get a single driver duty issue
     *
     * @param int $id
     * @return \Illuminate\Http\JsonResponse
     */
    public function show($id)
    {
        try {
            $issue = DriverDutyIssue::with(['deliveryBoy', 'deliveryBoy.city'])->find($id);

            if (!$issue) {
                return CommonHelper::responseError('Issue not found.');
            }

            return CommonHelper::responseWithData($issue);

        } catch (Exception $e) {
            Log::error("Get Driver Duty Issue Error: ", [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError('Failed to fetch issue.');
        }
    }

    /**
     * Delete a driver duty issue
     *
     * @param int $id
     * @return \Illuminate\Http\JsonResponse
     */
    public function destroy($id)
    {
        try {
            $issue = DriverDutyIssue::find($id);

            if (!$issue) {
                return CommonHelper::responseError('Issue not found.');
            }

            $issue->delete();

            return CommonHelper::responseSuccess('Issue deleted successfully.');

        } catch (Exception $e) {
            Log::error("Delete Driver Duty Issue Error: ", [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError('Failed to delete issue.');
        }
    }
}