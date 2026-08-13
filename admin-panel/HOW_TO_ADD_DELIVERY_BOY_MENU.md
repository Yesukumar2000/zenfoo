# How to Add Delivery Boy Menu to Your Existing Sidebar

Your admin panel uses a **dynamic menu system** that loads menu items from an API endpoint (`/api/menu`). Here are the steps to add the Delivery Boy menu items to your existing sidebar.

---

## Option 1: Add Menu Items Through Database (Recommended)

### Step 1: Find Your Menu Table

First, identify your menu table in the database. Common names are:
- `menus`
- `admin_menus`
- `navigation_menus`
- `sidebar_menus`

```bash
# Check your database
php artisan tinker
# Then run:
DB::select('SHOW TABLES');
```

### Step 2: Check Your Menu Structure

Look at existing menu items in your database:

```sql
SELECT * FROM your_menu_table LIMIT 5;
```

Note the column names (likely: `id`, `name`, `slug`, `icon`, `href`, `parent_id`, `order`, etc.)

### Step 3: Insert Delivery Boy Menu Items

I've prepared a JSON file with all menu items: **[DELIVERY_BOY_MENU_ITEMS.json](DELIVERY_BOY_MENU_ITEMS.json)**

You can insert them manually or use the seeder I created.

#### Method A: Use the Seeder (Easiest)

1. Open **[database/seeders/DeliveryBoyMenuSeeder.php](database/seeders/DeliveryBoyMenuSeeder.php)**

2. Update the table name on line 162:
```php
// Change this:
// DB::table('menus')->insert($menuItem);

// To your actual table name:
DB::table('your_actual_menu_table')->insert($menuItem);
```

3. Run the seeder:
```bash
php artisan db:seed --class=DeliveryBoyMenuSeeder
```

#### Method B: Manual SQL Insert

If you prefer SQL, here's an example for the main menu items:

```sql
-- Delivery Partners Section Title
INSERT INTO your_menu_table (name, slug, icon, href, `order`, parent_id, created_at, updated_at)
VALUES ('Delivery Partners', 'title', NULL, NULL, 100, NULL, NOW(), NOW());

-- Dashboard
INSERT INTO your_menu_table (name, slug, icon, href, `order`, parent_id, created_at, updated_at)
VALUES ('Dashboard', 'link', 'cil-speedometer', '/delivery-boy/dashboard', 101, NULL, NOW(), NOW());

-- Registrations Dropdown
INSERT INTO your_menu_table (name, slug, icon, href, `order`, parent_id, created_at, updated_at)
VALUES ('Registrations', 'dropdown', 'cil-user-plus', '/delivery-boy/registrations', 102, NULL, NOW(), NOW());

-- Get the last inserted ID for Registrations parent
SET @registrations_id = LAST_INSERT_ID();

-- Registrations Sub-items
INSERT INTO your_menu_table (name, slug, icon, href, parent_id, created_at, updated_at)
VALUES
('Pending Verification', 'link', 'cil-clock', '/delivery-boy/registrations/pending', @registrations_id, NOW(), NOW()),
('All Registrations', 'link', 'cil-list', '/delivery-boy/registrations/all', @registrations_id, NOW(), NOW()),
('Rejected', 'link', 'cil-x-circle', '/delivery-boy/registrations/rejected', @registrations_id, NOW(), NOW());

-- Continue for all other menu items...
```

---

## Option 2: Add Menu Items Through Admin Panel

If your admin panel has a menu management interface:

1. Go to your admin panel menu management page
2. Add each item from the **[DELIVERY_BOY_MENU_ITEMS.json](DELIVERY_BOY_MENU_ITEMS.json)** file
3. Use the following structure:

### Main Sections to Add:

#### 1. **Delivery Partners** (Title/Header)
- Type: Title
- Name: Delivery Partners

#### 2. **Dashboard**
- Type: Link
- Name: Dashboard
- Icon: cil-speedometer
- URL: /delivery-boy/dashboard

#### 3. **Registrations** (Dropdown)
- Type: Dropdown
- Name: Registrations
- Icon: cil-user-plus
- Sub-items:
  - Pending Verification → /delivery-boy/registrations/pending
  - All Registrations → /delivery-boy/registrations/all
  - Rejected → /delivery-boy/registrations/rejected

#### 4. **Partners** (Dropdown)
- Type: Dropdown
- Name: Partners
- Icon: cil-people
- Sub-items:
  - All Partners → /delivery-boy/partners/all
  - Active Partners → /delivery-boy/partners/active
  - Inactive Partners → /delivery-boy/partners/inactive

#### 5. **Document Verification**
- Type: Link
- Name: Document Verification
- Icon: cil-file
- URL: /delivery-boy/documents/verification

#### 6. **Gig Management** (Title/Header)
- Type: Title
- Name: Gig Management

#### 7. **Gigs** (Dropdown)
- Type: Dropdown
- Name: Gigs
- Icon: cil-briefcase
- Sub-items:
  - All Gigs → /delivery-boy/gigs/list
  - Create Gig → /delivery-boy/gigs/create
  - Gig Slots Calendar → /delivery-boy/gigs/calendar

#### 8. **Bookings**
- Type: Link
- Name: Bookings
- Icon: cil-bookmark
- URL: /delivery-boy/gigs/bookings

#### 9. **Tracking & Analytics** (Title/Header)
- Type: Title
- Name: Tracking & Analytics

#### 10. **Live Tracking**
- Type: Link
- Name: Live Tracking
- Icon: cil-location-pin
- URL: /delivery-boy/tracking/live

#### 11. **Session History**
- Type: Link
- Name: Session History
- Icon: cil-history
- URL: /delivery-boy/tracking/sessions

#### 12. **Daily Reports**
- Type: Link
- Name: Daily Reports
- Icon: cil-chart-line
- URL: /delivery-boy/tracking/reports

#### 13. **Incentives** (Title/Header)
- Type: Title
- Name: Incentives

#### 14. **Offers** (Dropdown)
- Type: Dropdown
- Name: Offers
- Icon: cil-gift
- Sub-items:
  - All Offers → /delivery-boy/offers/list
  - Create Offer → /delivery-boy/offers/create
  - Active Offers → /delivery-boy/offers/active

#### 15. **Partner Progress**
- Type: Link
- Name: Partner Progress
- Icon: cil-chart-pie
- URL: /delivery-boy/offers/progress

#### 16. **Payout Management**
- Type: Link
- Name: Payout Management
- Icon: cil-dollar
- URL: /delivery-boy/offers/payouts

#### 17. **Settings** (Title/Header)
- Type: Title
- Name: Settings

#### 18. **Store Locations**
- Type: Link
- Name: Store Locations
- Icon: cil-home
- URL: /delivery-boy/settings/locations

#### 19. **Vehicles**
- Type: Link
- Name: Vehicles
- Icon: cil-truck
- URL: /delivery-boy/settings/vehicles

---

## Option 3: Temporarily Use Static Menu (For Testing)

If you want to test the menu immediately without changing the database, you can temporarily modify **TheSidebar.vue**:

### Step 1: Import the Static Menu

In `resources/js/containers/TheSidebar.vue`, add this at the top of the `<script>` section:

```javascript
import DeliveryBoyNav from './_nav_deliveryboy'
```

### Step 2: Modify the Mounted Hook

Replace the API call with the static menu for testing:

```javascript
mounted () {
  // ... existing code ...

  // TEMPORARY: Use static menu for testing
  this.nav = DeliveryBoyNav

  // Comment out the API call temporarily:
  /*
  axios.get( this.$apiAdress + '/api/menu?token=' + localStorage.getItem("api_token") )
  .then(function (response) {
    self.nav = self.rebuildData(response.data);
  }).catch(function (error) {
    self.$router.push({ path: '/login' });
  });
  */
}
```

**Note:** This is only for testing! For production, use Option 1 or 2.

---

## Verifying the Menu

After adding the menu items, you should see this structure in your sidebar:

```
📊 Delivery Partners
  ⚡ Dashboard
  👥 Registrations
    ⏰ Pending Verification
    📋 All Registrations
    ❌ Rejected
  👨‍💼 Partners
    👤 All Partners
    ✅ Active Partners
    🚫 Inactive Partners
  📄 Document Verification

💼 Gig Management
  💼 Gigs
    📋 All Gigs
    ➕ Create Gig
    📅 Gig Slots Calendar
  🔖 Bookings

📈 Tracking & Analytics
  📍 Live Tracking
  🕐 Session History
  📊 Daily Reports

🎁 Incentives
  🎁 Offers
    📋 All Offers
    ➕ Create Offer
    ⭐ Active Offers
  📊 Partner Progress
  💰 Payout Management

⚙️ Settings
  🏠 Store Locations
  🚛 Vehicles
```

---

## Troubleshooting

### Menu items don't appear
1. Check if the API endpoint `/api/menu` is returning the new items
2. Clear browser cache and reload
3. Check browser console for JavaScript errors

### Menu items appear but clicking doesn't work
1. Make sure you've added the Vue routes (see [ADMIN_VUE_ROUTES_SETUP.md](ADMIN_VUE_ROUTES_SETUP.md))
2. Check that the Vue components are in the correct folders

### Icons don't show
1. Make sure CoreUI icons are properly installed
2. Check that the icon names match CoreUI icon library

---

## Need Help?

If you're unsure about your menu table structure, run this command to see your existing menu:

```bash
php artisan tinker
```

Then:

```php
// Check what table stores the menu
DB::select('SHOW TABLES');

// Look at existing menu structure
DB::table('your_menu_table')->first();
```

Share the output, and I can create exact SQL queries for your specific database structure!
