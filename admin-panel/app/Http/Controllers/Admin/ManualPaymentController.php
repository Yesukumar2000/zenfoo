<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\DeliveryBoyManualPayment;
use App\Models\DeliveryBoy;
use App\Services\ManualPaymentService;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Auth;

class ManualPaymentController extends Controller
{
    /**
     * Display list of manual payment submissions
     *
     * @param Request $request
     * @return \Illuminate\View\View
     */
    public function index(Request $request)
    {
        $status = $request->input('status', 'all');

        $query = DeliveryBoyManualPayment::with(['deliveryBoy', 'approvedByAdmin'])
            ->orderBy('created_at', 'desc');

        if ($status !== 'all') {
            $query->where('status', $status);
        }

        $payments = $query->paginate(20);

        return view('admin.manual-payments.index', compact('payments', 'status'));
    }

    /**
     * Show details of a manual payment
     *
     * @param int $id
     * @return \Illuminate\View\View
     */
    public function show($id)
    {
        $payment = DeliveryBoyManualPayment::with(['deliveryBoy', 'approvedByAdmin'])
            ->findOrFail($id);

        return view('admin.manual-payments.show', compact('payment'));
    }

    /**
     * Approve a manual payment
     *
     * @param Request $request
     * @param int $id
     * @return \Illuminate\Http\RedirectResponse
     */
    public function approve(Request $request, $id)
    {
        $payment = DeliveryBoyManualPayment::findOrFail($id);

        if (!$payment->isPending()) {
            return redirect()->back()->with('error', 'Payment has already been processed');
        }

        $validator = Validator::make($request->all(), [
            'admin_notes' => 'nullable|string|max:500',
        ]);

        if ($validator->fails()) {
            return redirect()->back()->withErrors($validator)->withInput();
        }

        $result = ManualPaymentService::approvePayment(
            $payment,
            Auth::id(),
            $request->input('admin_notes')
        );

        if ($result['success']) {
            return redirect()->route('admin.manual-payments.index')
                ->with('success', $result['message'] . ' (Settled: ₹' . $result['settled_amount'] . ')');
        } else {
            return redirect()->back()->with('error', $result['message']);
        }
    }

    /**
     * Reject a manual payment
     *
     * @param Request $request
     * @param int $id
     * @return \Illuminate\Http\RedirectResponse
     */
    public function reject(Request $request, $id)
    {
        $payment = DeliveryBoyManualPayment::findOrFail($id);

        if (!$payment->isPending()) {
            return redirect()->back()->with('error', 'Payment has already been processed');
        }

        $validator = Validator::make($request->all(), [
            'admin_notes' => 'required|string|max:500',
        ]);

        if ($validator->fails()) {
            return redirect()->back()->withErrors($validator)->withInput();
        }

        $result = ManualPaymentService::rejectPayment(
            $payment,
            Auth::id(),
            $request->input('admin_notes')
        );

        if ($result['success']) {
            return redirect()->route('admin.manual-payments.index')
                ->with('success', $result['message']);
        } else {
            return redirect()->back()->with('error', $result['message']);
        }
    }

    /**
     * Show form to manually reduce hand cash for a delivery boy
     *
     * @param int $deliveryBoyId
     * @return \Illuminate\View\View
     */
    public function showManualReductionForm($deliveryBoyId)
    {
        $deliveryBoy = DeliveryBoy::findOrFail($deliveryBoyId);
        return view('admin.manual-payments.manual-reduction', compact('deliveryBoy'));
    }

    /**
     * Manually reduce hand cash for a delivery boy
     *
     * @param Request $request
     * @param int $deliveryBoyId
     * @return \Illuminate\Http\RedirectResponse
     */
    public function manuallyReduceHandCash(Request $request, $deliveryBoyId)
    {
        $validator = Validator::make($request->all(), [
            'amount' => 'required|numeric|min:1',
            'reason' => 'nullable|string|max:500',
        ]);

        if ($validator->fails()) {
            return redirect()->back()->withErrors($validator)->withInput();
        }

        $result = ManualPaymentService::manuallyReduceHandCash(
            $deliveryBoyId,
            $request->input('amount'),
            Auth::id(),
            $request->input('reason')
        );

        if ($result['success']) {
            return redirect()->back()
                ->with('success', $result['message'] . ' (Settled: ₹' . $result['settled_amount'] . ')');
        } else {
            return redirect()->back()->with('error', $result['message']);
        }
    }

    /**
     * API endpoint to get all manual payment submissions (for API consumers)
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function apiIndex(Request $request)
    {
        $status = $request->input('status', 'all');

        $query = DeliveryBoyManualPayment::with(['deliveryBoy', 'approvedByAdmin'])
            ->orderBy('created_at', 'desc');

        if ($status !== 'all') {
            $query->where('status', $status);
        }

        $payments = $query->paginate(20);

        // Add unpaid hand cash for each payment's delivery boy
        foreach ($payments as $payment) {
            if ($payment->deliveryBoy) {
                $payment->unpaid_hand_cash = $this->getUnpaidHandCash($payment->delivery_boy_id);
            }
        }

        return response()->json([
            'success' => true,
            'data' => $payments,
        ]);
    }

    /**
     * Get unpaid hand cash (sum of unsettled admin_cash) for a delivery boy
     *
     * @param int $deliveryBoyId
     * @return float
     */
    private function getUnpaidHandCash($deliveryBoyId)
    {
        return \App\Models\DeliveryBoyTransaction::where('delivery_boy_id', $deliveryBoyId)
            ->where('settled_with_admin', 0)
            ->where('admin_cash', '>', 0)
            ->sum('admin_cash');
    }

    /**
     * API endpoint to approve payment
     *
     * @param Request $request
     * @param int $id
     * @return \Illuminate\Http\JsonResponse
     */
    public function apiApprove(Request $request, $id)
    {
        $payment = DeliveryBoyManualPayment::findOrFail($id);

        if (!$payment->isPending()) {
            return response()->json([
                'success' => false,
                'message' => 'Payment has already been processed',
            ], 400);
        }

        $validator = Validator::make($request->all(), [
            'admin_notes' => 'nullable|string|max:500',
            'amount_received' => 'nullable|numeric|min:0',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => $validator->errors()->first(),
            ], 422);
        }

        $result = ManualPaymentService::approvePayment(
            $payment,
            Auth::id(),
            $request->input('admin_notes'),
            $request->input('amount_received')
        );

        return response()->json($result, $result['success'] ? 200 : 500);
    }

    /**
     * API endpoint to reject payment
     *
     * @param Request $request
     * @param int $id
     * @return \Illuminate\Http\JsonResponse
     */
    public function apiReject(Request $request, $id)
    {
        $payment = DeliveryBoyManualPayment::findOrFail($id);

        if (!$payment->isPending()) {
            return response()->json([
                'success' => false,
                'message' => 'Payment has already been processed',
            ], 400);
        }

        $validator = Validator::make($request->all(), [
            'admin_notes' => 'required|string|max:500',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => $validator->errors()->first(),
            ], 422);
        }

        $result = ManualPaymentService::rejectPayment(
            $payment,
            Auth::id(),
            $request->input('admin_notes')
        );

        return response()->json($result, $result['success'] ? 200 : 500);
    }

    /**
     * API endpoint to manually reduce hand cash
     *
     * @param Request $request
     * @param int $deliveryBoyId
     * @return \Illuminate\Http\JsonResponse
     */
    public function apiManuallyReduceHandCash(Request $request, $deliveryBoyId)
    {
        $validator = Validator::make($request->all(), [
            'amount' => 'required|numeric|min:1',
            'reason' => 'nullable|string|max:500',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => $validator->errors()->first(),
            ], 422);
        }

        $result = ManualPaymentService::manuallyReduceHandCash(
            $deliveryBoyId,
            $request->input('amount'),
            Auth::id(),
            $request->input('reason')
        );

        return response()->json($result, $result['success'] ? 200 : 500);
    }
}
