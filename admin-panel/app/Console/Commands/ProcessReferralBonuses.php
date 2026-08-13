<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Jobs\ProcessReferralBonusAfterReturnPeriod;
use App\Models\Order;
use App\Models\OrderStatus;
use App\Models\OrderStatusList;
use App\Models\Setting;
use App\Models\WalletTransaction;
use Carbon\Carbon;

class ProcessReferralBonuses extends Command
{
    protected $signature = 'referral:process-bonuses {--days=180 : Only scan orders delivered within this many days}';

    protected $description = 'Reconcile referral bonuses: dispatch processing jobs for delivered, eligible, uncredited first orders';

    public function handle()
    {
        $referralMinOrderAmount = (float) Setting::get_value('referral_min_order_amount');
        $sinceDays = (int) $this->option('days');
        $since = Carbon::now()->subDays($sinceDays > 0 ? $sinceDays : 180);

        $dispatched = 0;
        $skipped = 0;

        // Candidate orders: delivered, placed by a user who used a referral
        // code, meeting the minimum order amount. Everything else (first-order
        // check, idempotency, return window) is re-validated below and again
        // inside the job, so this is a safe superset.
        Order::query()
            ->where('active_status', OrderStatusList::$delivered)
            ->where('final_total', '>=', $referralMinOrderAmount)
            ->where('created_at', '>=', $since)
            ->whereHas('user', function ($q) {
                $q->whereNotNull('friends_code')->where('friends_code', '!=', '');
            })
            ->with(['user', 'items.productVariant.product'])
            ->chunkById(200, function ($orders) use (&$dispatched, &$skipped) {
                foreach ($orders as $order) {
                    if ($this->dispatchIfEligible($order)) {
                        $dispatched++;
                    } else {
                        $skipped++;
                    }
                }
            });

        $this->info("Referral reconcile complete. Dispatched: {$dispatched}, skipped: {$skipped}.");
        return 0;
    }

    /**
     * Re-validate eligibility and dispatch the (idempotent) crediting job,
     * delayed until the return window closes when returnable items are present.
     */
    private function dispatchIfEligible(Order $order): bool
    {
        $user = $order->user;
        if (!$user || !$user->friends_code) {
            return false;
        }

        // Must be the user's first delivered order -- compared by id, not by
        // "any other". Running retroactively, `!=` let a customer's own later
        // orders disqualify their genuine first one, permanently losing the
        // referrer's bonus whenever the reconcile lagged behind a repeat order.
        $earlierDelivered = Order::where('user_id', $user->id)
            ->where('active_status', OrderStatusList::$delivered)
            ->where('id', '<', $order->id)
            ->exists();
        if ($earlierDelivered) {
            return false;
        }

        // One referral bonus per referred customer, ever. Checking per-customer
        // rather than per-order is what keeps the `<` comparison above safe when
        // orders are delivered out of sequence.
        $alreadyCredited = WalletTransaction::where('message', 'Refer Earn First Order Bonus')
            ->whereIn('order_id', Order::where('user_id', $user->id)->select('id'))
            ->exists();
        if ($alreadyCredited) {
            return false;
        }

        // Determine the longest return window across the order's items.
        $maxReturnDays = 0;
        foreach ($order->items as $item) {
            $product = $item->productVariant->product ?? null;
            if ($product && $product->return_status == 1 && $product->return_days > 0) {
                $maxReturnDays = max($maxReturnDays, (int) $product->return_days);
            }
        }

        if ($maxReturnDays === 0) {
            // No returnable items — credit now.
            ProcessReferralBonusAfterReturnPeriod::dispatch($order->id);
            return true;
        }

        $deliveredStatus = OrderStatus::where('order_id', $order->id)
            ->where('status', OrderStatusList::$delivered)
            ->orderBy('created_at', 'desc')
            ->first();
        $deliveredAt = $deliveredStatus
            ? Carbon::parse($deliveredStatus->created_at)
            : Carbon::parse($order->updated_at);

        $returnPeriodEnd = $deliveredAt->copy()->addDays($maxReturnDays);
        $delay = Carbon::now()->diffInSeconds($returnPeriodEnd, false);

        if ($delay > 0) {
            // Still within the return window — process once it closes.
            ProcessReferralBonusAfterReturnPeriod::dispatch($order->id)
                ->delay(Carbon::now()->addSeconds($delay));
        } else {
            // Window already elapsed — process now.
            ProcessReferralBonusAfterReturnPeriod::dispatch($order->id);
        }

        return true;
    }
}
