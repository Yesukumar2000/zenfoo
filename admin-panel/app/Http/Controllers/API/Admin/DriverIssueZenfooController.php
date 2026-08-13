<?php

namespace App\Http\Controllers\API\Admin;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\DeliveryBoyTransaction;
use App\Models\DriverIssueZenfoo;
use App\Services\DriverNotificationService;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class DriverIssueZenfooController extends Controller
{
    /**
     * Get all driver issues with filters
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function index(Request $request)
    {
        try {
            $query = DriverIssueZenfoo::with(['deliveryBoy', 'deliveryBoy.city'])
                ->orderBy('id', 'desc');

            // Filter by issue_type
            if ($request->has('issue_type') && $request->issue_type != '') {
                $query->where('issue_type', $request->issue_type);
            }

            // Filter by status
            if ($request->has('status') && $request->status != '') {
                $query->where('status', $request->status);
            }

            // Filter by city_id (through delivery_boy relationship)
            if ($request->has('city_id') && $request->city_id != '') {
                $query->whereHas('deliveryBoy', function ($q) use ($request) {
                    $q->where('city_id', $request->city_id);
                });
            }

            $issues = $query->get();

            return CommonHelper::responseWithData($issues);

        } catch (Exception $e) {
            Log::error("Get Driver Issues Zenfoo Error: ", [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError('Failed to fetch driver issues.');
        }
    }

    /**
     * Get a single driver issue by ID
     *
     * @param int $id
     * @return \Illuminate\Http\JsonResponse
     */
    public function show($id)
    {
        try {
            $issue = DriverIssueZenfoo::with(['deliveryBoy', 'deliveryBoy.city'])->find($id);

            if (!$issue) {
                return CommonHelper::responseError('Issue not found.');
            }

            return CommonHelper::responseWithData($issue);

        } catch (Exception $e) {
            Log::error("Get Driver Issue Error: ", [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError('Failed to fetch issue.');
        }
    }

    /**
     * Respond to a driver issue (update status and admin_message)
     *
     * @param Request $request
     * @param int $id
     * @return \Illuminate\Http\JsonResponse
     */
    public function respond(Request $request, $id)
    {
        try {
            $validator = Validator::make($request->all(), [
                'status' => 'required|in:pending,resolved,rejected',
                'admin_message' => 'nullable|string|max:5000',
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $issue = DriverIssueZenfoo::find($id);

            if (!$issue) {
                return CommonHelper::responseError('Issue not found.');
            }

            $issue->status = $request->status;
            $issue->admin_message = $request->admin_message;
            $issue->save();

            // Send notification to driver
            $this->sendIssueStatusNotification($issue);

            return CommonHelper::responseSuccess('Issue updated successfully.');

        } catch (Exception $e) {
            Log::error("Respond to Driver Issue Error: ", [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError('Failed to update issue.');
        }
    }

    /**
     * Get transactions by IDs (for payout/incentive issues)
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getTransactions(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'ids' => 'required|array',
                'ids.*' => 'integer',
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $transactions = DeliveryBoyTransaction::with(['order'])
                ->whereIn('id', $request->ids)
                ->get()
                ->map(function ($transaction) {
                    return [
                        'id' => $transaction->id,
                        'order_id' => $transaction->order_id,
                        'type' => $transaction->type,
                        'amount' => $transaction->amount,
                        'delivery_charge' => $transaction->delivery_charge ?? 0,
                        'delivery_tip' => $transaction->delivery_tip ?? 0,
                        'bonus_amount' => $transaction->bonus_amount ?? 0,
                        'driver_earnings' => $transaction->driver_earnings ?? 0,
                        'admin_cash' => $transaction->admin_cash ?? 0,
                        'status' => $transaction->status,
                        'message' => $transaction->message,
                        'transaction_date' => $transaction->transaction_date,
                        'payout_reference' => $transaction->payout_reference ?? null,
                        'settled_at' => $transaction->settled_at ?? null,
                        'is_hand_cash' => $transaction->is_hand_cash ?? 0,
                        'created_at' => $transaction->created_at,
                    ];
                });

            return CommonHelper::responseWithData($transactions);

        } catch (Exception $e) {
            Log::error("Get Transactions Error: ", [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError('Failed to fetch transactions.');
        }
    }

    /**
     * Send notification to driver about issue status update
     *
     * @param DriverIssueZenfoo $issue
     * @return void
     */
    private function sendIssueStatusNotification(DriverIssueZenfoo $issue)
    {
        try {
            if (!$issue->driver_id) {
                Log::warning("Cannot send notification: No driver_id for issue #{$issue->id}");
                return;
            }

            // Format issue type for display
            $issueTypeLabels = [
                'order_earning' => 'Order Earning',
                'incorrect_payout' => 'Incorrect Payout',
                'incentive' => 'Incentive',
                'multi_order' => 'Multi Order',
                'joining_bonus' => 'Joining Bonus',
                'pocketing_issue' => 'Pocketing Issue',
                'not_getting_order_issue' => 'Not Getting Orders',
                'extra_floating_deposited' => 'Extra Floating Deposited',
                'cash_deposit_issue' => 'Cash Deposit Issue'
            ];
            $issueTypeLabel = $issueTypeLabels[$issue->issue_type] ?? $issue->issue_type;

            // Build notification title and message based on status
            switch ($issue->status) {
                case 'resolved':
                    $title = 'Issue Resolved';
                    $message = "Your {$issueTypeLabel} issue (#{$issue->id}) has been resolved.";
                    break;
                case 'rejected':
                    $title = 'Issue Rejected';
                    $message = "Your {$issueTypeLabel} issue (#{$issue->id}) has been rejected.";
                    break;
                case 'pending':
                default:
                    $title = 'Issue Update';
                    $message = "Your {$issueTypeLabel} issue (#{$issue->id}) is being reviewed.";
                    break;
            }

            // Append admin message if provided
            if (!empty($issue->admin_message)) {
                $message .= " Admin message: " . $issue->admin_message;
            }

            // Send notification using DriverNotificationService
            $result = DriverNotificationService::send(
                $issue->driver_id,
                $title,
                $message,
                '',
                'issue_update',
                null,
                [
                    'issue_id' => $issue->id,
                    'issue_type' => $issue->issue_type,
                    'status' => $issue->status
                ]
            );

            Log::info("Issue status notification sent", [
                'issue_id' => $issue->id,
                'driver_id' => $issue->driver_id,
                'status' => $issue->status,
                'notification_result' => $result
            ]);

        } catch (Exception $e) {
            // Log error but don't fail the response
            Log::error("Failed to send issue status notification", [
                'issue_id' => $issue->id,
                'error' => $e->getMessage()
            ]);
        }
    }
}
