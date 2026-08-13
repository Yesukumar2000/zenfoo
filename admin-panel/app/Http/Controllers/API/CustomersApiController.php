<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\City;
use App\Models\Order;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CustomersApiController extends Controller
{
    /*public function index(){}*/

    public function getCustomers(Request $request){

        $limit = $request->get('limit',5);
        $offset = $request->get('offset',0);

        // Filter by deleted status
        if ($request->show_deleted == 'true' || $request->show_deleted == '1') {
            // Show ONLY deleted users
            $query = User::onlyTrashed()->withCount('orders')->where('users.status','!=', 2);
        } else {
            // Show only active (non-deleted) users
            $query = User::withCount('orders')->where('users.status','!=', 2);
        }

        if ($request->filled('city_id')) {
            $query->leftJoin('user_addresses', function ($join) {
                $join->on('user_addresses.user_id', '=', 'users.id')
                     ->where('user_addresses.is_default', '=', 1);
            });

            if ($request->city_id === 'other') {
                $allCityIds = City::pluck('id');
                $query->where(function ($q) use ($allCityIds) {
                    $q->whereNull('user_addresses.city_id')
                      ->orWhere('user_addresses.city_id', 0)
                      ->orWhere('user_addresses.city_id', '')
                      ->orWhereNotIn('user_addresses.city_id', $allCityIds);
                });
            } else {
                $query->where('user_addresses.city_id', $request->city_id);
            }
        }

        if ($request->has('search')) {
            $searchTerm = $request->input('search');
            $query->where(function ($query) use ($searchTerm) {
                $query->where('name', 'like', '%'.$searchTerm.'%')
                    ->orWhere('email', 'like', '%'.$searchTerm.'%')
                    ->orWhere('mobile', 'like', '%'.$searchTerm.'%')
                    ->orWhere('balance', 'like', '%'.$searchTerm.'%')
                    ->orWhere('referral_code', 'like', '%'.$searchTerm.'%')
                    ->orWhere('friends_code', 'like', '%'.$searchTerm.'%')
                    ->orWhere('status', 'like', '%'.$searchTerm.'%');
            });
        }

        // Apply sorting - default to orders_count descending
        $sortColumn = $request->input('sort_by', 'orders_count');
        $sortDirection = $request->input('sort_dir', 'desc');
        $query->orderBy($sortColumn, $sortDirection);

        // Get the total count for pagination
        $total = $query->count();
        $customers = $query->get();

        return CommonHelper::responseWithData($customers, $total);
    }
    public function changeStatus(Request $request){
        if(isset($request->id)){
            $customers = User::find($request->id);
            if($customers){
                $customers->status = ( $customers->status == 1 ) ? 0 : 1;
                $customers->save();
                return CommonHelper::responseSuccess("Customers Status Updated Successfully!");
            }else{
                return CommonHelper::responseSuccess("Customer Record not found!");
            }
        }
    }

    public function getCustomer($id){
        $customer = User::withTrashed()->withCount('orders')->find($id);
        if($customer){
            return CommonHelper::responseSuccessWithData("Customer fetched successfully!", $customer);
        }else{
            return CommonHelper::responseError("Customer not found!");
        }
    }

    public function updateCustomer(Request $request, $id){
        $customer = User::withTrashed()->find($id);
        if(!$customer){
            return CommonHelper::responseError("Customer not found!");
        }

        // Validate email uniqueness (exclude current customer)
        if($request->has('email') && $request->email != $customer->email){
            $emailExists = User::where('email', $request->email)
                ->where('id', '!=', $id)
                ->exists();
            if($emailExists){
                return CommonHelper::responseError("Email already exists for another user!");
            }
        }

        // Validate mobile uniqueness (exclude current customer)
        if($request->has('mobile') && $request->mobile != $customer->mobile){
            $mobileExists = User::where('mobile', $request->mobile)
                ->where('id', '!=', $id)
                ->exists();
            if($mobileExists){
                return CommonHelper::responseError("Mobile number already exists for another user!");
            }
        }

        // Update customer details
        if($request->has('name')){
            $customer->name = $request->name;
        }
        if($request->has('email')){
            $customer->email = $request->email;
        }
        if($request->has('mobile')){
            $customer->mobile = $request->mobile;
        }
        if($request->has('status')){
            $customer->status = $request->status;
        }

        $customer->save();

        return CommonHelper::responseSuccessWithData("Customer updated successfully!", $customer);
    }

    /**
     * Get customer analytics data
     */
    public function getCustomerAnalytics($id)
    {
        $customer = User::withTrashed()->find($id);
        if (!$customer) {
            return CommonHelper::responseError("Customer not found!");
        }

        // Order Statistics (excluding Payment Pending status = 1)
        $totalOrders = Order::where('user_id', $id)->where('active_status', '!=', 1)->count();
        $deliveredOrders = Order::where('user_id', $id)->where('active_status', 6)->count();
        $cancelledOrders = Order::where('user_id', $id)->where('active_status', 7)->count();
        $returnedOrders = Order::where('user_id', $id)->where('active_status', 8)->count();

        $totalSpent = Order::where('user_id', $id)
            ->where('active_status', 6) // Only delivered orders
            ->sum('final_total');

        $avgOrderValue = $deliveredOrders > 0 ? round($totalSpent / $deliveredOrders, 2) : 0;

        // Orders by Status (excluding Payment Pending status = 1)
        $ordersByStatus = Order::where('user_id', $id)
            ->where('active_status', '!=', 1)
            ->select('active_status', DB::raw('count(*) as count'))
            ->groupBy('active_status')
            ->get()
            ->map(function ($item) {
                $statusNames = [
                    1 => 'Payment Pending',
                    2 => 'Received',
                    3 => 'Processed',
                    4 => 'Shipped',
                    5 => 'Out For Delivery',
                    6 => 'Delivered',
                    7 => 'Cancelled',
                    8 => 'Returned',
                    9 => 'Pending',
                    10 => 'Ready for Pickup',
                    11 => 'Picked Up'
                ];
                return [
                    'status' => $item->active_status,
                    'status_name' => $statusNames[$item->active_status] ?? 'Unknown',
                    'count' => $item->count
                ];
            });

        // Monthly Trends (last 6 months)
        $monthlyTrends = Order::where('user_id', $id)
            ->where('created_at', '>=', now()->subMonths(6))
            ->select(
                DB::raw('YEAR(created_at) as year'),
                DB::raw('MONTH(created_at) as month'),
                DB::raw('COUNT(*) as order_count'),
                DB::raw('SUM(CASE WHEN active_status = 6 THEN final_total ELSE 0 END) as total_spent')
            )
            ->groupBy(DB::raw('YEAR(created_at)'), DB::raw('MONTH(created_at)'))
            ->orderBy('year', 'asc')
            ->orderBy('month', 'asc')
            ->get()
            ->map(function ($item) {
                $monthName = date('M Y', mktime(0, 0, 0, $item->month, 1, $item->year));
                return [
                    'month' => $monthName,
                    'month_num' => $item->month,
                    'year' => $item->year,
                    'order_count' => $item->order_count,
                    'total_spent' => round($item->total_spent, 2)
                ];
            });

        // First and Last order dates
        $firstOrder = Order::where('user_id', $id)->orderBy('created_at', 'asc')->first();
        $lastOrder = Order::where('user_id', $id)->orderBy('created_at', 'desc')->first();

        $analytics = [
            'order_statistics' => [
                'total_orders' => $totalOrders,
                'delivered_orders' => $deliveredOrders,
                'cancelled_orders' => $cancelledOrders,
                'returned_orders' => $returnedOrders,
                'total_spent' => round($totalSpent, 2),
                'avg_order_value' => $avgOrderValue
            ],
            'orders_by_status' => $ordersByStatus,
            'monthly_trends' => $monthlyTrends,
            'first_order_date' => $firstOrder ? $firstOrder->created_at->format('d M Y') : null,
            'last_order_date' => $lastOrder ? $lastOrder->created_at->format('d M Y') : null
        ];

        return CommonHelper::responseSuccessWithData("Analytics fetched successfully!", $analytics);
    }
}
