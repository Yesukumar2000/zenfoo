<?php

namespace App\Jobs;

use App\Models\Order;
use App\Models\PendingDeliveryAssignment;
use App\Models\OrderDeliveryBoyNotification;
use App\Services\FirestoreDeliveryBoyService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class RetryDeliveryBoyAssignmentJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    /**
     * Legacy fixed values — kept as fallbacks. The live cadence and attempt
     * count are now derived from the admin "tiered dispatch" settings via the
     * helpers below (offerTimeoutSeconds()/maxAttempts()).
     */
    const MAX_ATTEMPTS = 5;
    const RETRY_DELAY_SECONDS = 30;

    /**
     * Extra cycles to keep offering once the radius has reached the admin max,
     * so a driver who comes online / finishes a ride near the outer edge can
     * still pick the order up before we give up.
     */
    const EXTRA_CYCLES_AT_MAX = 3;

    /**
     * Short delay used to skip past an empty ring (no available driver in range
     * yet) without burning the full offer timeout.
     */
    const EMPTY_RING_DELAY_SECONDS = 4;

    protected int $orderId;
    protected int $attempt;
    protected string $chainId;

    /**
     * Framework-level tries — set to 1 because we handle retries via self re-dispatch.
     */
    public $tries = 1;
    public $maxExceptions = 1;

    public function __construct(int $orderId, int $attempt = 1, string $chainId = '')
    {
        $this->orderId = $orderId;
        $this->attempt = $attempt;
        $this->chainId = $chainId;
    }

    /**
     * Offer timeout (seconds) per ring, from admin settings.
     */
    public static function offerTimeoutSeconds(): int
    {
        return FirestoreDeliveryBoyService::dispatchOfferTimeoutSeconds();
    }

    /**
     * The search radius (km) to use for a given retry attempt. The radius grows
     * one tier step per attempt — ring 2 on the first retry, ring 3 on the next,
     * and so on — capped at the admin max radius. (Ring 1 is the initial offer
     * fired immediately by the dispatch call site.)
     */
    public static function radiusForAttempt(int $attempt): float
    {
        $step = FirestoreDeliveryBoyService::dispatchTierStepKm();
        $max  = FirestoreDeliveryBoyService::dispatchMaxRadiusKm();

        return min($step * ($attempt + 1), $max);
    }

    /**
     * How many retry attempts it takes to expand from ring 2 out to the admin
     * max radius, plus a few extra cycles held at the max radius.
     */
    public static function maxAttempts(): int
    {
        $step = FirestoreDeliveryBoyService::dispatchTierStepKm();
        $max  = FirestoreDeliveryBoyService::dispatchMaxRadiusKm();

        $ringsToMax = max(1, (int) ceil($max / $step) - 1);

        return $ringsToMax + self::EXTRA_CYCLES_AT_MAX;
    }

    /**
     * Start a new retry chain for an order. Cancels any existing chain.
     * Default delay is the admin offer timeout (time ring 1 gets before ring 2).
     */
    public static function dispatchForOrder(int $orderId, ?int $delaySeconds = null): void
    {
        if ($delaySeconds === null) {
            $delaySeconds = self::offerTimeoutSeconds();
        }

        // Cancel existing chain
        self::cancelExistingForOrder($orderId);

        // Generate a new chain ID and store it as the active one. Keep the chain
        // marker alive for the full worst-case run (all rings × offer timeout)
        // plus a buffer, so a long expansion can't expire its own guard mid-run.
        $chainTtlSeconds = (self::maxAttempts() + 1) * (self::offerTimeoutSeconds() + 5) + 120;
        $chainId = Str::uuid()->toString();
        Cache::put("retry_chain_{$orderId}", $chainId, now()->addSeconds(max(600, $chainTtlSeconds)));

        self::dispatch($orderId, 1, $chainId)
            ->delay(now()->addSeconds($delaySeconds));

        Log::info('RetryDeliveryBoyAssignment: New chain dispatched', [
            'order_id' => $orderId,
            'chain_id' => $chainId,
            'delay_seconds' => $delaySeconds,
        ]);
    }

    /**
     * Cancel all existing retry jobs for an order.
     */
    public static function cancelExistingForOrder(int $orderId): int
    {
        // Invalidate the active chain so any running job stops
        Cache::forget("retry_chain_{$orderId}");

        $deleted = DB::table('jobs')
            ->where('payload', 'like', '%RetryDeliveryBoyAssignmentJob%')
            ->where('payload', 'like', '%"orderId";i:' . $orderId . ';%')
            ->delete();

        if ($deleted > 0) {
            Log::info('RetryDeliveryBoyAssignment: Cancelled existing jobs', [
                'order_id' => $orderId,
                'jobs_cancelled' => $deleted,
            ]);
        }

        return $deleted;
    }

    /**
     * Check if a retry job is active in the queue for an order.
     */
    public static function isActiveForOrder(int $orderId): bool
    {
        // Check both: cache has an active chain AND a job exists in queue
        return Cache::has("retry_chain_{$orderId}") || DB::table('jobs')
            ->where('payload', 'like', '%RetryDeliveryBoyAssignmentJob%')
            ->where('payload', 'like', '%"orderId";i:' . $orderId . ';%')
            ->exists();
    }

    public function handle(): void
    {
        $radiusKm = self::radiusForAttempt($this->attempt);

        Log::info('RetryDeliveryBoyAssignment: Starting', [
            'order_id' => $this->orderId,
            'attempt' => $this->attempt,
            'max_attempts' => self::maxAttempts(),
            'radius_km' => $radiusKm,
            'chain_id' => $this->chainId,
        ]);

        // Guard: Check if this chain is still the active one
        $activeChainId = Cache::get("retry_chain_{$this->orderId}");
        if ($this->chainId && $activeChainId !== $this->chainId) {
            Log::info('RetryDeliveryBoyAssignment: Chain superseded, stopping', [
                'order_id' => $this->orderId,
                'my_chain' => $this->chainId,
                'active_chain' => $activeChainId,
            ]);
            return;
        }

        // Guard: Order must exist
        $order = Order::find($this->orderId);
        if (!$order) {
            Log::warning('RetryDeliveryBoyAssignment: Order not found, stopping', [
                'order_id' => $this->orderId,
            ]);
            return;
        }

        // Guard: Driver already assigned
        if ($order->delivery_boy_id) {
            Log::info('RetryDeliveryBoyAssignment: Driver already assigned, stopping', [
                'order_id' => $this->orderId,
                'delivery_boy_id' => $order->delivery_boy_id,
            ]);
            Cache::forget("retry_chain_{$this->orderId}");
            return;
        }

        // Guard: Order status must still be valid for assignment (2=received, 3=processed)
        if (!in_array((int) $order->active_status, [2, 3])) {
            Log::info('RetryDeliveryBoyAssignment: Order status no longer valid, stopping', [
                'order_id' => $this->orderId,
                'active_status' => $order->active_status,
            ]);
            Cache::forget("retry_chain_{$this->orderId}");
            return;
        }

        // Expire previous 'sent' notifications so drivers get fresh notifications
        OrderDeliveryBoyNotification::where('order_id', $this->orderId)
            ->where('status', OrderDeliveryBoyNotification::STATUS_SENT)
            ->each(function (OrderDeliveryBoyNotification $notification) {
                $notification->markAsExpired();
            });

        // Retry finding and notifying drivers within the current (expanding) ring
        $driversFound = 0;
        try {
            $result = FirestoreDeliveryBoyService::getAndSyncAvailableDeliveryBoys($this->orderId, $radiusKm);
            $driversFound = count($result['not_on_ride'] ?? []);

            Log::info('RetryDeliveryBoyAssignment: Attempt completed', [
                'order_id' => $this->orderId,
                'attempt' => $this->attempt,
                'radius_km' => $radiusKm,
                'drivers_found' => $driversFound,
                'firestore_success' => $result['firestore_sync']['success'] ?? false,
            ]);
        } catch (\Exception $e) {
            Log::error('RetryDeliveryBoyAssignment: Service call failed', [
                'order_id' => $this->orderId,
                'attempt' => $this->attempt,
                'error' => $e->getMessage(),
            ]);
        }

        // Re-check if a driver was assigned during the search
        $order->refresh();
        if ($order->delivery_boy_id) {
            Log::info('RetryDeliveryBoyAssignment: Driver assigned during retry, stopping', [
                'order_id' => $this->orderId,
                'delivery_boy_id' => $order->delivery_boy_id,
            ]);
            Cache::forget("retry_chain_{$this->orderId}");
            return;
        }

        // Re-dispatch or mark as failed
        if ($this->attempt >= self::maxAttempts()) {
            Log::warning('RetryDeliveryBoyAssignment: Max attempts reached', [
                'order_id' => $this->orderId,
                'attempts' => $this->attempt,
                'radius_km' => $radiusKm,
            ]);

            $pending = PendingDeliveryAssignment::where('order_id', $this->orderId)
                ->where('status', PendingDeliveryAssignment::STATUS_PENDING)
                ->first();

            if ($pending) {
                $pending->markAsFailed("Auto-retry exhausted after {$this->attempt} attempts — no driver accepted");
            }

            Cache::forget("retry_chain_{$this->orderId}");
            return;
        }

        // Decide the delay before expanding to the next ring.
        // If this ring had no available driver and we can still expand outward,
        // skip ahead quickly instead of making the order wait the full timeout
        // for a ring that nobody is in. Otherwise give the current ring its full
        // offer window to accept before widening the net.
        $atMaxRadius = $radiusKm >= FirestoreDeliveryBoyService::dispatchMaxRadiusKm();

        if ($driversFound === 0 && !$atMaxRadius) {
            $delaySeconds = self::EMPTY_RING_DELAY_SECONDS + rand(0, 2);
        } else {
            // Add random jitter to prevent all orders retrying at the same instant
            $delaySeconds = self::offerTimeoutSeconds() + rand(0, 5);
        }

        self::dispatch($this->orderId, $this->attempt + 1, $this->chainId)
            ->delay(now()->addSeconds($delaySeconds));

        Log::info('RetryDeliveryBoyAssignment: Re-dispatched', [
            'order_id' => $this->orderId,
            'next_attempt' => $this->attempt + 1,
            'next_radius_km' => self::radiusForAttempt($this->attempt + 1),
            'delay_seconds' => $delaySeconds,
            'empty_ring_fast_forward' => ($driversFound === 0 && !$atMaxRadius),
        ]);
    }

    public function failed(\Throwable $exception): void
    {
        Log::error('RetryDeliveryBoyAssignment: Job failed', [
            'order_id' => $this->orderId,
            'attempt' => $this->attempt,
            'error' => $exception->getMessage(),
        ]);
    }
}
