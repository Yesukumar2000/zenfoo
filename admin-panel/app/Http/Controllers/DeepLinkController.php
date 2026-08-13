<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class DeepLinkController extends Controller
{
    /**
     * Handle deep links for the Zenfoo app
     * Routes app:// or zenfoo:// links to appropriate screens
     * Examples:
     *   zenfoo://payment/deposit_cash
     *   zenfoo://payment/status
     *   zenfoo://payout/history
     */
    public function handleDeepLink($module, $screen, Request $request)
    {
        try {
            // Validate module and screen parameters
            $validModules = ['payment', 'payout', 'order', 'profile', 'settings'];

            if (!in_array($module, $validModules)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Invalid module',
                    'error' => 'Unknown module: ' . $module
                ], 404);
            }

            // Build the response with app routing information
            $deepLinkData = $this->buildDeepLinkResponse($module, $screen, $request);

            return response()->json([
                'success' => true,
                'data' => $deepLinkData
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to process deep link',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Build the deep link response based on module and screen
     */
    private function buildDeepLinkResponse($module, $screen, Request $request)
    {
        $response = [
            'module' => $module,
            'screen' => $screen,
            'app_link' => "zenfoo://{$module}/{$screen}",
            'timestamp' => now()->toIso8601String()
        ];

        // Module-specific data
        switch ($module) {
            case 'payment':
                $response = array_merge($response, $this->getPaymentDeepLinkData($screen));
                break;

            case 'payout':
                $response = array_merge($response, $this->getPayoutDeepLinkData($screen));
                break;

            case 'order':
                $response = array_merge($response, $this->getOrderDeepLinkData($screen));
                break;

            case 'profile':
                $response = array_merge($response, $this->getProfileDeepLinkData($screen));
                break;

            case 'settings':
                $response = array_merge($response, $this->getSettingsDeepLinkData($screen));
                break;
        }

        return $response;
    }

    /**
     * Payment module deep links
     */
    private function getPaymentDeepLinkData($screen)
    {
        $data = [
            'screen_type' => 'payment_screen',
            'action_required' => false
        ];

        switch ($screen) {
            case 'deposit_cash':
                $data['screen_type'] = 'payment_deposit_screen';
                $data['action_required'] = true;
                $data['title'] = 'Deposit Cash to Zenfoo';
                $data['description'] = 'Complete the cash deposit to resume accepting orders';
                $data['icon'] = 'payment';
                break;

            case 'status':
                $data['screen_type'] = 'payment_status_screen';
                $data['title'] = 'Payment Status';
                $data['description'] = 'View your payment and settlement details';
                $data['icon'] = 'info';
                break;

            case 'history':
                $data['screen_type'] = 'payment_history_screen';
                $data['title'] = 'Payment History';
                $data['description'] = 'View your transaction history';
                $data['icon'] = 'history';
                break;
        }

        return $data;
    }

    /**
     * Payout module deep links
     */
    private function getPayoutDeepLinkData($screen)
    {
        $data = [
            'screen_type' => 'payout_screen'
        ];

        switch ($screen) {
            case 'history':
                $data['screen_type'] = 'payout_history_screen';
                $data['title'] = 'Payout History';
                $data['description'] = 'View your payout transactions';
                $data['icon'] = 'history';
                break;

            case 'summary':
                $data['screen_type'] = 'payout_summary_screen';
                $data['title'] = 'Payout Summary';
                $data['description'] = 'View your earnings summary';
                $data['icon'] = 'summary';
                break;
        }

        return $data;
    }

    /**
     * Order module deep links
     */
    private function getOrderDeepLinkData($screen)
    {
        $data = [
            'screen_type' => 'order_screen'
        ];

        switch ($screen) {
            case 'list':
                $data['screen_type'] = 'order_list_screen';
                $data['title'] = 'Orders';
                $data['description'] = 'View available orders';
                $data['icon'] = 'orders';
                break;

            case 'active':
                $data['screen_type'] = 'active_orders_screen';
                $data['title'] = 'Active Orders';
                $data['description'] = 'View your active deliveries';
                $data['icon'] = 'delivery';
                break;
        }

        return $data;
    }

    /**
     * Profile module deep links
     */
    private function getProfileDeepLinkData($screen)
    {
        $data = [
            'screen_type' => 'profile_screen'
        ];

        switch ($screen) {
            case 'info':
                $data['screen_type'] = 'profile_info_screen';
                $data['title'] = 'Profile Information';
                $data['description'] = 'Manage your profile details';
                $data['icon'] = 'person';
                break;

            case 'documents':
                $data['screen_type'] = 'profile_documents_screen';
                $data['title'] = 'Documents';
                $data['description'] = 'Manage your documents';
                $data['icon'] = 'documents';
                break;
        }

        return $data;
    }

    /**
     * Settings module deep links
     */
    private function getSettingsDeepLinkData($screen)
    {
        $data = [
            'screen_type' => 'settings_screen'
        ];

        switch ($screen) {
            case 'account':
                $data['screen_type'] = 'account_settings_screen';
                $data['title'] = 'Account Settings';
                $data['description'] = 'Manage your account';
                $data['icon'] = 'settings';
                break;

            case 'notifications':
                $data['screen_type'] = 'notification_settings_screen';
                $data['title'] = 'Notification Settings';
                $data['description'] = 'Manage notifications';
                $data['icon'] = 'notifications';
                break;
        }

        return $data;
    }

    /**
     * Return app links configuration for .well-known setup
     * This file helps both Android and iOS apps understand which routes support deep linking
     */
    public function getAppLinksConfig()
    {
        $config = [
            'version' => '1.0',
            'namespace' => 'https://' . request()->getHost(),
            'deep_links' => [
                [
                    'path' => '/app/payment/deposit_cash',
                    'module' => 'payment',
                    'screen' => 'deposit_cash',
                    'description' => 'Deposit cash to Zenfoo',
                    'android_intent' => 'zenfoo://payment/deposit_cash',
                    'ios_url' => 'zenfoo://payment/deposit_cash'
                ],
                [
                    'path' => '/app/payment/status',
                    'module' => 'payment',
                    'screen' => 'status',
                    'description' => 'View payment status',
                    'android_intent' => 'zenfoo://payment/status',
                    'ios_url' => 'zenfoo://payment/status'
                ],
                [
                    'path' => '/app/payout/history',
                    'module' => 'payout',
                    'screen' => 'history',
                    'description' => 'View payout history',
                    'android_intent' => 'zenfoo://payout/history',
                    'ios_url' => 'zenfoo://payout/history'
                ],
                [
                    'path' => '/app/order/list',
                    'module' => 'order',
                    'screen' => 'list',
                    'description' => 'View orders',
                    'android_intent' => 'zenfoo://order/list',
                    'ios_url' => 'zenfoo://order/list'
                ],
                [
                    'path' => '/app/profile/info',
                    'module' => 'profile',
                    'screen' => 'info',
                    'description' => 'View profile',
                    'android_intent' => 'zenfoo://profile/info',
                    'ios_url' => 'zenfoo://profile/info'
                ]
            ]
        ];

        return response()->json($config)
            ->header('Content-Type', 'application/json')
            ->header('Access-Control-Allow-Origin', '*');
    }
}
