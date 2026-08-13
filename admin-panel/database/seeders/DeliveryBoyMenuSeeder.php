<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class DeliveryBoyMenuSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        // This seeder adds Delivery Boy menu items to your existing menu system
        // Adjust table name and structure based on your actual menu table

        $deliveryBoyMenu = [
            [
                'name' => 'Delivery Partners',
                'slug' => 'title',
                'icon' => null,
                'href' => null,
                'order' => 100,
                'parent_id' => null,
            ],
            [
                'name' => 'Dashboard',
                'slug' => 'link',
                'icon' => 'cil-speedometer',
                'href' => '/delivery-boy/dashboard',
                'order' => 101,
                'parent_id' => null,
            ],
            [
                'name' => 'Registrations',
                'slug' => 'dropdown',
                'icon' => 'cil-user-plus',
                'href' => '/delivery-boy/registrations',
                'order' => 102,
                'parent_id' => null,
                'elements' => [
                    [
                        'name' => 'Pending Verification',
                        'slug' => 'link',
                        'icon' => 'cil-clock',
                        'href' => '/delivery-boy/registrations/pending',
                    ],
                    [
                        'name' => 'All Registrations',
                        'slug' => 'link',
                        'icon' => 'cil-list',
                        'href' => '/delivery-boy/registrations/all',
                    ],
                    [
                        'name' => 'Rejected',
                        'slug' => 'link',
                        'icon' => 'cil-x-circle',
                        'href' => '/delivery-boy/registrations/rejected',
                    ],
                ],
            ],
            [
                'name' => 'Partners',
                'slug' => 'dropdown',
                'icon' => 'cil-people',
                'href' => '/delivery-boy/partners',
                'order' => 103,
                'parent_id' => null,
                'elements' => [
                    [
                        'name' => 'All Partners',
                        'slug' => 'link',
                        'icon' => 'cil-user',
                        'href' => '/delivery-boy/partners/all',
                    ],
                    [
                        'name' => 'Active Partners',
                        'slug' => 'link',
                        'icon' => 'cil-check-circle',
                        'href' => '/delivery-boy/partners/active',
                    ],
                    [
                        'name' => 'Inactive Partners',
                        'slug' => 'link',
                        'icon' => 'cil-ban',
                        'href' => '/delivery-boy/partners/inactive',
                    ],
                ],
            ],
            [
                'name' => 'Document Verification',
                'slug' => 'link',
                'icon' => 'cil-file',
                'href' => '/delivery-boy/documents/verification',
                'order' => 104,
                'parent_id' => null,
            ],
            [
                'name' => 'Gig Management',
                'slug' => 'title',
                'icon' => null,
                'href' => null,
                'order' => 105,
                'parent_id' => null,
            ],
            [
                'name' => 'Gigs',
                'slug' => 'dropdown',
                'icon' => 'cil-briefcase',
                'href' => '/delivery-boy/gigs',
                'order' => 106,
                'parent_id' => null,
                'elements' => [
                    [
                        'name' => 'All Gigs',
                        'slug' => 'link',
                        'icon' => 'cil-list',
                        'href' => '/delivery-boy/gigs/list',
                    ],
                    [
                        'name' => 'Create Gig',
                        'slug' => 'link',
                        'icon' => 'cil-plus',
                        'href' => '/delivery-boy/gigs/create',
                    ],
                    [
                        'name' => 'Gig Slots Calendar',
                        'slug' => 'link',
                        'icon' => 'cil-calendar',
                        'href' => '/delivery-boy/gigs/calendar',
                    ],
                ],
            ],
            [
                'name' => 'Bookings',
                'slug' => 'link',
                'icon' => 'cil-bookmark',
                'href' => '/delivery-boy/gigs/bookings',
                'order' => 107,
                'parent_id' => null,
            ],
            [
                'name' => 'Tracking & Analytics',
                'slug' => 'title',
                'icon' => null,
                'href' => null,
                'order' => 108,
                'parent_id' => null,
            ],
            [
                'name' => 'Live Tracking',
                'slug' => 'link',
                'icon' => 'cil-location-pin',
                'href' => '/delivery-boy/tracking/live',
                'order' => 109,
                'parent_id' => null,
            ],
            [
                'name' => 'Session History',
                'slug' => 'link',
                'icon' => 'cil-history',
                'href' => '/delivery-boy/tracking/sessions',
                'order' => 110,
                'parent_id' => null,
            ],
            [
                'name' => 'Daily Reports',
                'slug' => 'link',
                'icon' => 'cil-chart-line',
                'href' => '/delivery-boy/tracking/reports',
                'order' => 111,
                'parent_id' => null,
            ],
            [
                'name' => 'Incentives',
                'slug' => 'title',
                'icon' => null,
                'href' => null,
                'order' => 112,
                'parent_id' => null,
            ],
            [
                'name' => 'Offers',
                'slug' => 'dropdown',
                'icon' => 'cil-gift',
                'href' => '/delivery-boy/offers',
                'order' => 113,
                'parent_id' => null,
                'elements' => [
                    [
                        'name' => 'All Offers',
                        'slug' => 'link',
                        'icon' => 'cil-list',
                        'href' => '/delivery-boy/offers/list',
                    ],
                    [
                        'name' => 'Create Offer',
                        'slug' => 'link',
                        'icon' => 'cil-plus',
                        'href' => '/delivery-boy/offers/create',
                    ],
                    [
                        'name' => 'Active Offers',
                        'slug' => 'link',
                        'icon' => 'cil-star',
                        'href' => '/delivery-boy/offers/active',
                    ],
                ],
            ],
            [
                'name' => 'Partner Progress',
                'slug' => 'link',
                'icon' => 'cil-chart-pie',
                'href' => '/delivery-boy/offers/progress',
                'order' => 114,
                'parent_id' => null,
            ],
            [
                'name' => 'Payout Management',
                'slug' => 'link',
                'icon' => 'cil-dollar',
                'href' => '/delivery-boy/offers/payouts',
                'order' => 115,
                'parent_id' => null,
            ],
            [
                'name' => 'Settings',
                'slug' => 'title',
                'icon' => null,
                'href' => null,
                'order' => 116,
                'parent_id' => null,
            ],
            [
                'name' => 'Store Locations',
                'slug' => 'link',
                'icon' => 'cil-home',
                'href' => '/delivery-boy/settings/locations',
                'order' => 117,
                'parent_id' => null,
            ],
            [
                'name' => 'Vehicles',
                'slug' => 'link',
                'icon' => 'cil-truck',
                'href' => '/delivery-boy/settings/vehicles',
                'order' => 118,
                'parent_id' => null,
            ],
        ];

        // Insert menu items
        // NOTE: Adjust table name and column names based on your actual database schema
        foreach ($deliveryBoyMenu as $menuItem) {
            $elements = $menuItem['elements'] ?? null;
            unset($menuItem['elements']);

            // Insert parent menu item
            // DB::table('menus')->insert($menuItem);

            // If you need to insert into a specific menu table, use:
            // $parentId = DB::table('your_menu_table')->insertGetId($menuItem);

            // If has sub-elements (dropdown), insert them as children
            if ($elements) {
                foreach ($elements as $element) {
                    // $element['parent_id'] = $parentId;
                    // DB::table('your_menu_table')->insert($element);
                }
            }
        }

        $this->command->info('✅ Delivery Boy menu items structure prepared!');
        $this->command->info('   📝 Please adjust the DB::table() calls with your actual menu table name.');
        $this->command->info('   📝 The menu structure is ready to be inserted into your database.');
    }
}
