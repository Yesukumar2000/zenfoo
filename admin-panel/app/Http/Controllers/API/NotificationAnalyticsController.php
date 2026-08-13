<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\BroadcastNotification;
use App\Models\DeliveryBoyBroadcastNotification;
use App\Models\DeliveryBoyNotification;
use App\Models\Notification;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Notification Analytics — Phase 1.
 *
 * IMPORTANT: every figure returned here is derived from tables that already
 * exist. Metrics the platform does not yet track (delivered receipts,
 * read/opened for customer/seller/driver, per-channel SMS/Email/WhatsApp,
 * scheduled sends, alert/escalation rules) are NOT faked — they are reported
 * as unavailable via the `availability` block so the UI can label them
 * honestly instead of inventing numbers.
 */
class NotificationAnalyticsController extends Controller
{
    /** Resolve from/to range (defaults to last 30 days). */
    private function range(Request $request)
    {
        $to   = $request->filled('to_date')   ? Carbon::parse($request->to_date)->endOfDay()      : Carbon::now()->endOfDay();
        $from = $request->filled('from_date') ? Carbon::parse($request->from_date)->startOfDay()  : Carbon::now()->subDays(30)->startOfDay();
        return [$from, $to];
    }

    // =====================================================================
    //  OVERVIEW
    // =====================================================================
    public function overview(Request $request)
    {
        try {
            [$from, $to] = $this->range($request);

            // --- Per-recipient sent rows (the real "sent" events) ---------
            $custSent   = Notification::where('role_name', 'customer')->whereBetween('date_sent', [$from, $to])->count();
            $sellerSent = Notification::where('role_name', 'seller')->whereBetween('date_sent', [$from, $to])->count();
            $driverSent = DeliveryBoyNotification::whereBetween('created_at', [$from, $to])->count();
            $totalSent  = $custSent + $sellerSent + $driverSent;

            // --- Broadcast aggregates (the only sent/failed tracking) -----
            $bSent = (int) BroadcastNotification::whereBetween('created_at', [$from, $to])->sum('total_sent');
            $bFail = (int) BroadcastNotification::whereBetween('created_at', [$from, $to])->sum('total_failed');
            $broadcastCount = BroadcastNotification::whereBetween('created_at', [$from, $to])->count();

            $dbbSuccess = 0; $dbbFail = 0; $dbbCount = 0; $pending = 0;
            if (Schema::hasTable('delivery_boy_broadcast_notifications')) {
                $dbbSuccess = (int) DeliveryBoyBroadcastNotification::whereBetween('created_at', [$from, $to])->sum('success_count');
                $dbbFail    = (int) DeliveryBoyBroadcastNotification::whereBetween('created_at', [$from, $to])->sum('failed_count');
                $dbbCount   = DeliveryBoyBroadcastNotification::whereBetween('created_at', [$from, $to])->count();
                $pending    = DeliveryBoyBroadcastNotification::whereIn('status', ['pending', 'sending'])->count();
            }

            $reached = $bSent + $dbbSuccess;   // FCM-accepted at send time (NOT device delivery receipts)
            $failed  = $bFail + $dbbFail;

            // --- Subscribers: registered FCM devices ----------------------
            $subscribers = 0;
            if (Schema::hasTable('user_tokens'))  $subscribers += DB::table('user_tokens')->whereNotNull('fcm_token')->count();
            if (Schema::hasTable('admin_tokens')) $subscribers += DB::table('admin_tokens')->whereNotNull('fcm_token')->count();

            // --- Admin in-app read tracking (the ONLY read data we have) --
            $panelTotal = 0; $panelRead = 0;
            if (Schema::hasTable('panel_notifications')) {
                $panelTotal = DB::table('panel_notifications')->count();
                $panelRead  = DB::table('panel_notifications')->whereNotNull('read_at')->count();
            }
            $adminReadRate = $panelTotal ? round($panelRead * 100 / $panelTotal, 1) : 0;

            $stats = [
                'total_sent'    => $totalSent,
                'reached'       => $reached,
                'failed'        => $failed,
                'pending'       => $pending,
                'broadcasts'    => $broadcastCount + $dbbCount,
                'subscribers'   => $subscribers,
                // secondary / honesty metrics
                'admin_read_rate'   => $adminReadRate,
                'admin_read_count'  => $panelRead,
                'admin_read_total'  => $panelTotal,
            ];

            return response()->json([
                'status' => 1,
                'data'   => [
                    'stats'                => $stats,
                    'notification_trend'   => $this->trend($from, $to),
                    'by_audience'          => $this->byAudience($from, $to),
                    'by_type'              => $this->byType($from, $to),
                    'delivery_status'      => ['reached' => $reached, 'failed' => $failed],
                    'recent_notifications' => $this->recentNotifications(),
                    'recent_broadcasts'    => $this->recentBroadcasts(),
                    'availability'         => $this->availability(),
                ],
            ]);
        } catch (\Exception $e) {
            return response()->json(['status' => 0, 'message' => 'Failed to load overview: ' . $e->getMessage()], 500);
        }
    }

    /** Daily sent counts across the range (customer/seller + driver). */
    private function trend($from, $to)
    {
        $labels = []; $cursor = $from->copy()->startOfDay();
        $map = [];
        while ($cursor->lte($to)) {
            $key = $cursor->format('Y-m-d');
            $labels[] = $key;
            $map[$key] = 0;
            $cursor->addDay();
        }
        // Cap huge ranges to keep the chart readable.
        if (count($labels) > 90) {
            $labels = array_slice($labels, -90);
            $map = array_intersect_key($map, array_flip($labels));
        }

        $users = Notification::whereBetween('date_sent', [$from, $to])
            ->select(DB::raw('DATE(date_sent) as d'), DB::raw('COUNT(*) as c'))
            ->groupBy('d')->pluck('c', 'd');
        $drivers = DeliveryBoyNotification::whereBetween('created_at', [$from, $to])
            ->select(DB::raw('DATE(created_at) as d'), DB::raw('COUNT(*) as c'))
            ->groupBy('d')->pluck('c', 'd');

        foreach ($map as $d => $_) {
            $map[$d] = (int) ($users[$d] ?? 0) + (int) ($drivers[$d] ?? 0);
        }

        return ['labels' => array_keys($map), 'sent' => array_values($map)];
    }

    /** Donut: notifications by audience (customer / seller / driver). */
    private function byAudience($from, $to)
    {
        return [
            ['name' => 'Customer', 'count' => Notification::where('role_name', 'customer')->whereBetween('date_sent', [$from, $to])->count()],
            ['name' => 'Seller',   'count' => Notification::where('role_name', 'seller')->whereBetween('date_sent', [$from, $to])->count()],
            ['name' => 'Driver',   'count' => DeliveryBoyNotification::whereBetween('created_at', [$from, $to])->count()],
        ];
    }

    /** Donut: notifications by type (top 6). */
    private function byType($from, $to)
    {
        $rows = Notification::whereBetween('date_sent', [$from, $to])
            ->select('type', DB::raw('COUNT(*) as c'))
            ->groupBy('type')->orderByDesc('c')->limit(6)->get();
        return $rows->map(function ($r) {
            return ['name' => $r->type ?: 'Unspecified', 'count' => (int) $r->c];
        })->values();
    }

    /** Recent per-recipient notifications, merged across audiences. */
    private function recentNotifications()
    {
        $users = Notification::orderByDesc('date_sent')->limit(8)
            ->get(['id', 'title', 'message', 'type', 'role_name', 'date_sent'])
            ->map(function ($n) {
                return [
                    'id'       => 'N' . $n->id,
                    'title'    => $n->title,
                    'type'     => $n->type,
                    'audience' => ucfirst($n->role_name ?: 'customer'),
                    'channel'  => 'Push',
                    'sent_at'  => (string) $n->date_sent,
                ];
            });

        $drivers = DeliveryBoyNotification::orderByDesc('created_at')->limit(8)
            ->get(['id', 'title', 'message', 'type', 'created_at'])
            ->map(function ($n) {
                return [
                    'id'       => 'D' . $n->id,
                    'title'    => $n->title,
                    'type'     => $n->type,
                    'audience' => 'Driver',
                    'channel'  => 'Push',
                    'sent_at'  => (string) $n->created_at,
                ];
            });

        return $users->concat($drivers)->sortByDesc('sent_at')->take(8)->values();
    }

    /** Recent broadcasts with their real sent/failed aggregates. */
    private function recentBroadcasts()
    {
        return BroadcastNotification::orderByDesc('created_at')->limit(8)
            ->get(['id', 'target_type', 'title', 'total_sent', 'total_failed', 'created_at'])
            ->map(function ($b) {
                return [
                    'id'         => $b->id,
                    'target'     => ucfirst($b->target_type),
                    'title'      => $b->title,
                    'sent'       => (int) $b->total_sent,
                    'failed'     => (int) $b->total_failed,
                    'created_at' => (string) $b->created_at,
                ];
            });
    }

    /** What is / isn't tracked today — drives the UI's honest labelling. */
    private function availability()
    {
        return [
            'sent'            => true,
            'failed'          => true,   // aggregate only, at send time
            'pending'         => true,   // driver broadcasts only
            'delivered'       => false,  // no FCM delivery receipts ingested
            'read_customer'   => false,  // apps don't report opens back
            'read_admin'      => true,   // panel_notifications.read_at
            'channels'        => false,  // push only; no channel dimension
            'whatsapp'        => false,
            'scheduled'       => false,
            'alert_rules'     => false,
            'escalation'      => false,
            'note'            => 'Sent, failed (aggregate), pending, by-audience and by-type come from live data. Delivered, read/opened, per-channel, scheduled, alert & escalation rules require new tracking (Phase 2+).',
        ];
    }

    // =====================================================================
    //  NOTIFICATIONS (list)
    // =====================================================================
    public function notifications(Request $request)
    {
        try {
            $audience = $request->get('audience', 'customer');   // customer|seller|driver
            $search   = $request->get('search', '');
            $perPage  = (int) $request->get('per_page', 15);

            if ($audience === 'driver') {
                $q = DeliveryBoyNotification::orderByDesc('created_at');
                if ($search) $q->where(function ($x) use ($search) {
                    $x->where('title', 'like', "%{$search}%")->orWhere('message', 'like', "%{$search}%");
                });
                $page = $q->paginate($perPage);
                $page->getCollection()->transform(function ($n) {
                    return [
                        'id' => $n->id, 'title' => $n->title, 'message' => $n->message,
                        'type' => $n->type, 'audience' => 'Driver', 'channel' => 'Push',
                        'sent_at' => (string) $n->created_at,
                    ];
                });
            } else {
                $q = Notification::where('role_name', $audience)->orderByDesc('date_sent');
                if ($search) $q->where(function ($x) use ($search) {
                    $x->where('title', 'like', "%{$search}%")->orWhere('message', 'like', "%{$search}%");
                });
                $page = $q->paginate($perPage);
                $page->getCollection()->transform(function ($n) use ($audience) {
                    return [
                        'id' => $n->id, 'title' => $n->title, 'message' => $n->message,
                        'type' => $n->type, 'audience' => ucfirst($audience), 'channel' => 'Push',
                        'sent_at' => (string) $n->date_sent,
                    ];
                });
            }

            return response()->json(['status' => 1, 'data' => $page]);
        } catch (\Exception $e) {
            return response()->json(['status' => 0, 'message' => $e->getMessage()], 500);
        }
    }

    // =====================================================================
    //  TEMPLATES  (sms_templates + email_templates — the only ones that exist)
    // =====================================================================
    public function templates()
    {
        try {
            $rows = collect();
            if (Schema::hasTable('sms_templates')) {
                foreach (DB::table('sms_templates')->orderBy('id')->get() as $t) {
                    $rows->push(['id' => $t->id, 'channel' => 'SMS', 'title' => $t->title, 'type' => $t->type, 'message' => $t->message]);
                }
            }
            if (Schema::hasTable('email_templates')) {
                foreach (DB::table('email_templates')->orderBy('id')->get() as $t) {
                    $rows->push(['id' => $t->id, 'channel' => 'Email', 'title' => $t->title, 'type' => $t->type, 'message' => $t->message]);
                }
            }
            return response()->json([
                'status' => 1,
                'data'   => [
                    'records' => $rows->values(),
                    'note'    => 'Push/WhatsApp templates are not stored yet — only SMS and Email templates exist.',
                ],
            ]);
        } catch (\Exception $e) {
            return response()->json(['status' => 0, 'message' => $e->getMessage()], 500);
        }
    }

    // =====================================================================
    //  DELIVERY LOGS  (broadcast history — real sent/failed per broadcast)
    // =====================================================================
    public function deliveryLogs(Request $request)
    {
        try {
            $logs = collect();

            foreach (BroadcastNotification::orderByDesc('created_at')->limit(50)->get() as $b) {
                $logs->push([
                    'id' => 'B' . $b->id, 'channel' => 'Push', 'target' => ucfirst($b->target_type),
                    'title' => $b->title, 'sent' => (int) $b->total_sent, 'failed' => (int) $b->total_failed,
                    'status' => $b->total_failed > 0 ? ($b->total_sent > 0 ? 'Partial' : 'Failed') : 'Completed',
                    'time' => (string) $b->created_at,
                ]);
            }
            if (Schema::hasTable('delivery_boy_broadcast_notifications')) {
                foreach (DeliveryBoyBroadcastNotification::orderByDesc('created_at')->limit(50)->get() as $d) {
                    $logs->push([
                        'id' => 'DB' . $d->id, 'channel' => 'Push', 'target' => 'Driver',
                        'title' => $d->title, 'sent' => (int) $d->success_count, 'failed' => (int) $d->failed_count,
                        'status' => ucfirst($d->status ?: 'completed'),
                        'time' => (string) ($d->sent_at ?: $d->created_at),
                    ]);
                }
            }

            return response()->json(['status' => 1, 'data' => ['records' => $logs->sortByDesc('time')->take(50)->values()]]);
        } catch (\Exception $e) {
            return response()->json(['status' => 0, 'message' => $e->getMessage()], 500);
        }
    }

    // =====================================================================
    //  SUBSCRIBERS  (registered FCM devices — real reach)
    // =====================================================================
    public function subscribers()
    {
        try {
            $byPlatform = collect();
            $byType = collect();

            if (Schema::hasTable('user_tokens')) {
                $rows = DB::table('user_tokens')->whereNotNull('fcm_token')
                    ->select('platform', 'type', DB::raw('COUNT(*) as c'))
                    ->groupBy('platform', 'type')->get();
                foreach ($rows as $r) {
                    $byPlatform->push(['platform' => $r->platform ?: 'unknown', 'type' => $r->type ?: 'customer', 'count' => (int) $r->c]);
                }
            }

            if (Schema::hasTable('user_tokens')) {
                $t = DB::table('user_tokens')->whereNotNull('fcm_token')
                    ->select('type', DB::raw('COUNT(*) as c'))->groupBy('type')->get();
                foreach ($t as $r) $byType->push(['name' => ucfirst($r->type ?: 'customer'), 'count' => (int) $r->c]);
            }
            if (Schema::hasTable('admin_tokens')) {
                $adminCount = DB::table('admin_tokens')->whereNotNull('fcm_token')->count();
                if ($adminCount) $byType->push(['name' => 'Admin', 'count' => $adminCount]);
            }

            return response()->json(['status' => 1, 'data' => ['by_platform' => $byPlatform->values(), 'by_type' => $byType->values()]]);
        } catch (\Exception $e) {
            return response()->json(['status' => 0, 'message' => $e->getMessage()], 500);
        }
    }
}
