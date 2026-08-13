<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\Order;
use App\Models\OrderStatusList;
use App\Models\Admin;
use App\Models\OrderStatus;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;
use App\Helpers\CommonHelper;
use App\Jobs\SendSellerOrderNotification;
use App\Jobs\SendEmailJob;
use App\Notifications\OrderNotification;
use App\Services\CustomerNotificationService;
use App\Services\AdminNotificationService;

class ProcessPreorders extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'preorders:process';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Process pending preorders and change their status from Preorder Pending to Received';

    /**
     * Create a new command instance.
     *
     * @return void
     */
    public function __construct()
    {
        parent::__construct();
    }

    /**
     * Execute the console command.
     *
     * @return int
     */
    public function handle()
    {
        $now = Carbon::now('Asia/Kolkata');
        $this->info("Processing preorders at: " . $now->toDateTimeString());

        // Find all preorders that are still in "Preorder Pending" status
        // and whose process date has arrived
        $preorders = Order::where('is_preorder', 1)
            ->where('active_status', OrderStatusList::$preorderPending)
            ->where('preorder_process_date', '<=', $now)
            ->get();

        if ($preorders->isEmpty()) {
            $this->info("No preorders found to process.");
            return 0;
        }

        $this->info("Found {$preorders->count()} preorder(s) to process.");

        $processedCount = 0;
        $failedCount = 0;

        foreach ($preorders as $order) {
            try {
                DB::beginTransaction();

                // Update order status from Preorder Pending to Received
                $order->active_status = OrderStatusList::$received;
                $order->save();

                // Log status change in order_statuses table
                DB::table('order_statuses')->insert([
                    'order_id' => $order->id,
                    'order_item_id' => null,
                    'status' => OrderStatusList::$received,
                    'created_by' => 0,
                    'user_type' => 0, // 0 = system automated process
                    'created_at' => $now
                ]);

                DB::commit();

                // Send all notifications after successful processing
                $this->sendNotifications($order);

                $this->info("✓ Processed Order #{$order->id}");
                $processedCount++;

                Log::info("Preorder processed", [
                    'order_id' => $order->id,
                    'user_id' => $order->user_id,
                    'old_status' => OrderStatusList::$preorderPending,
                    'new_status' => OrderStatusList::$received,
                    'processed_at' => $now->toDateTimeString()
                ]);

            } catch (\Exception $e) {
                DB::rollBack();
                $this->error("✗ Failed to process Order #{$order->id}: " . $e->getMessage());
                $failedCount++;

                Log::error("Preorder processing failed", [
                    'order_id' => $order->id,
                    'error' => $e->getMessage()
                ]);
            }
        }

        $this->info("\n" . str_repeat('=', 50));
        $this->info("Processing complete!");
        $this->info("Successfully processed: {$processedCount}");
        if ($failedCount > 0) {
            $this->warn("Failed: {$failedCount}");
        }
        $this->info(str_repeat('=', 50));

        return 0;
    }

    /**
     * Send notifications after processing preorder
     *
     * @param Order $order
     * @return void
     */
    private function sendNotifications($order)
    {
        try {
            // Send order status notification
            dispatch(function () use ($order) {
                CommonHelper::sendNotificationOrderStatus($order);

                // Notify all admins
                $admins = Admin::get();
                foreach ($admins as $admin) {
                    $admin->notify(new OrderNotification($order->id, 'new_order'));
                }
            })->afterResponse();
        } catch (\Exception $e) {
            Log::error("Preorder notification error", [
                'order_id' => $order->id,
                'error' => $e->getMessage()
            ]);
        }

        // Send push notification to customer
        try {
            CustomerNotificationService::send(
                customerId: $order->user_id,
                title: 'Your Preorder is Being Prepared!',
                message: "Your preorder #{$order->id} is now being processed. We'll keep you updated on the status.",
                image: '',
                pageNavigation: 'order',
                navigationId: $order->id
            );
            Log::info('Customer notification sent for preorder processing', [
                'order_id' => $order->id,
                'customer_id' => $order->user_id
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to send customer notification for preorder', [
                'order_id' => $order->id,
                'error' => $e->getMessage()
            ]);
        }

        // Send push notification to admin
        try {
            AdminNotificationService::notifyNewOrder($order->id, "Preorder #{$order->id}");
            Log::info('Admin notification sent for preorder processing', [
                'order_id' => $order->id
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to send admin notification for preorder', [
                'order_id' => $order->id,
                'error' => $e->getMessage()
            ]);
        }

        // Send notification to sellers
        try {
            Log::info("Dispatching seller notification for preorder", ['order_id' => $order->id]);
            dispatch(new SendSellerOrderNotification($order->id))->afterResponse();
        } catch (\Exception $e) {
            Log::error("Preorder seller notification error", [
                'order_id' => $order->id,
                'error' => $e->getMessage()
            ]);
        }

        // Send email
        try {
            Log::info("Sending email for preorder", ['order_id' => $order->id]);
            dispatch(new SendEmailJob($order))->afterResponse();
        } catch (\Exception $e) {
            Log::error("Preorder email error", [
                'order_id' => $order->id,
                'error' => $e->getMessage()
            ]);
        }

        // Send SMS
        try {
            CommonHelper::sendSmsOrderStatus($order, $order->active_status);
        } catch (\Exception $e) {
            Log::error("Preorder SMS error", [
                'order_id' => $order->id,
                'error' => $e->getMessage()
            ]);
        }
    }
}
