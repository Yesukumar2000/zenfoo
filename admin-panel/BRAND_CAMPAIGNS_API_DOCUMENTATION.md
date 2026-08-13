# Brand Campaigns API Documentation

## Overview
The Brand Campaigns API provides functionality for managing and retrieving a **single active brand promotional campaign** at a time. The system automatically selects the currently active campaign based on start/end dates and status.

## Database Structure

### Table: `brand_campaigns`
```
- id: Primary Key
- name: Campaign name
- description: Campaign description
- tagline: Marketing tagline
- primary_image_url: Main campaign image (URL)
- secondary_image_url: Secondary campaign image (URL)
- banners: JSON array of banner objects (max 3)
- brand_id: Optional - specific brand or NULL for multi-brand
- product_ids: JSON array of selected product IDs
- category_ids: JSON array of category IDs for filtering
- start_date: Campaign start date/time
- end_date: Campaign end date/time
- expired_at: Explicit expiry timestamp
- status: 1=active, 0=inactive
- is_featured: 1=featured, 0=normal
- display_order: For sorting when multiple campaigns exist
- campaign_type: brand_promotion, seasonal, flash_sale, bundle_offer
- metadata: JSON object for additional flexible data
- timestamps: created_at, updated_at
- soft_deletes: deleted_at
```

### Banner Structure (JSON)
```json
{
  "type": "image|video",
  "url": "https://...",
  "title": "Banner title",
  "description": "Banner description"
}
```

---

## API Endpoints

### 1. Get Current Active Campaign
**Endpoint:** `GET /api/customer/brand-campaigns`

**Description:** Returns the currently active campaign (only one). If no active campaign exists, returns null.

**Response (with active campaign):**
```json
{
  "status": 1,
  "message": "Success",
  "data": {
    "campaign": {
      "id": 1,
      "name": "Pure Goodness Sunflower Oil",
      "description": "Experience the purity and freshness of our premium sunflower oil collection...",
      "tagline": "Pure Goodness in Every Drop - Sunflower Oil for a Healthier You!",
      "primary_image_url": "https://via.placeholder.com/800x600?text=Sunflower+Oil+Main",
      "secondary_image_url": "https://via.placeholder.com/400x400?text=Sunflower+Oil+Secondary",
      "banners": [
        {
          "type": "image",
          "url": "https://via.placeholder.com/1200x400?text=Banner1",
          "title": "Premium Quality Oil",
          "description": "Cold-pressed, pure and natural"
        },
        {
          "type": "image",
          "url": "https://via.placeholder.com/1200x400?text=Banner2",
          "title": "Nature's Touch in Every Moment",
          "description": "Experience freshness like never before"
        },
        {
          "type": "image",
          "url": "https://via.placeholder.com/1200x400?text=Banner3",
          "title": "Bright Choices, Better Living",
          "description": "Empowering you with quality choices"
        }
      ],
      "brand_id": 1,
      "brand_name": "Brand Name",
      "product_ids": [1, 2, 3, 4, 5],
      "category_ids": [1, 2, 3],
      "campaign_type": "brand_promotion",
      "start_date": "2026-01-13 10:00:00",
      "end_date": "2026-02-12 10:00:00",
      "expired_at": "2026-02-27 10:00:00",
      "is_active": true,
      "is_expired": false,
      "is_featured": true,
      "display_order": 1,
      "days_until_expiry": 30,
      "metadata": {
        "discount_percentage": 10,
        "free_shipping": true,
        "target_audience": "health_conscious"
      }
    }
  }
}
```

**Response (no active campaign):**
```json
{
  "status": 1,
  "message": "Success",
  "data": {
    "campaign": null,
    "message": "No active campaign at the moment"
  }
}
```

---

### 2. Get Current Campaign Details with Products
**Endpoint:** `GET /api/customer/brand-campaigns/details`

**Description:** Returns the currently active campaign along with all associated products.

**Response:**
```json
{
  "status": 1,
  "message": "Success",
  "data": {
    "campaign": { ...campaign details },
    "products": [
      {
        "id": 1,
        "name": "Sunflower Cooking Oil",
        "slug": "sunflower-cooking-oil",
        "image": "https://...",
        "seller": {
          "id": 1,
          "name": "Seller Name"
        },
        "store": {
          "id": 1,
          "name": "Store Name"
        }
      },
      ...more products
    ],
    "products_count": 5,
    "days_until_expiry": 30,
    "message": "No active campaign at the moment" // Only if no campaign active
  }
}
```

---

### 3. Get Campaign by ID
**Endpoint:** `GET /api/customer/brand-campaigns/{id}`

**Parameters:**
- `id` (required): Campaign ID

**Description:** Returns a specific campaign details with associated products.

**Response:** Same as endpoint #2

---

## Automatic Campaign Selection Logic

The API automatically selects the current active campaign based on the following criteria:

1. **Status Check:** `status = 1` (active)
2. **Date Range Check:** Current date must be between `start_date` and `end_date`
3. **Expiry Check:** Either `expired_at` is NULL or current date <= `expired_at`
4. **Selection Order:**
   - Most recently started campaign first
   - Then by `display_order` (ascending)

**Example Timeline:**
```
Jan 1  ----[Campaign 1 Active]----  Jan 30
               Jan 31  ----[Campaign 2 Active]----  Feb 28
```

---

## Campaign Scheduling Strategy

### Current Campaign
- **Active Now**: All visitors see this campaign
- **Duration**: Runs from start_date to end_date

### Queued Campaigns
- **Not Yet Started**: Scheduled to start in future
- **Configuration**: Set up in advance, auto-activates on start_date

### Expired Campaigns
- **Ended**: No longer shown to visitors
- **Storage**: Kept in database for historical records (soft-deleted)

---

## How to Schedule Campaigns

### Campaign 1: Active Now
```php
BrandCampaign::create([
    'name' => 'Current Campaign',
    'start_date' => Carbon::now(),  // Today
    'end_date' => Carbon::now()->addDays(30),  // 30 days from now
    'status' => 1,
    ...
]);
```

### Campaign 2: Scheduled for Future (Auto-activates in 31 days)
```php
BrandCampaign::create([
    'name' => 'Next Campaign',
    'start_date' => Carbon::now()->addDays(31),  // Starts tomorrow
    'end_date' => Carbon::now()->addDays(61),  // 61 days from now
    'status' => 1,
    ...
]);
```

When Campaign 1 expires, Campaign 2 automatically becomes active!

---

## Field Specifications

### Primary and Secondary Images
- Full URLs stored in database
- Recommended sizes:
  - Primary: 800x600px
  - Secondary: 400x400px

### Banners (Up to 3)
Each banner contains:
- `type`: "image" or "video"
- `url`: Full URL to image or video
- `title`: Banner headline
- `description`: Banner subheading

### Product Selection
- `product_ids`: JSON array of product IDs
- Can be empty for general brand promotions
- Auto-loads product details when fetching details endpoint

### Category Filtering
- `category_ids`: Optional JSON array for filtering
- Used for categorized displays

---

## Metadata Object
Flexible JSON field for campaign-specific data:

```json
{
  "discount_percentage": 10,
  "free_shipping": true,
  "min_order_value": 500,
  "stock_limited": true,
  "urgency_level": "high",
  "target_audience": "health_conscious"
}
```

---

## Helper Methods (Model)

### Check Campaign Status
```php
$campaign = BrandCampaign::find(1);

// Check if campaign is currently active
if ($campaign->isActive()) {
    // Campaign is running
}

// Check if campaign has expired
if ($campaign->isExpired()) {
    // Campaign is no longer active
}

// Get days remaining
$days = $campaign->daysUntilExpiry();
echo "Campaign expires in: $days days";
```

### Get Current Campaign
```php
// Get the current active campaign
$campaign = BrandCampaign::current()->first();

if ($campaign) {
    echo "Current campaign: " . $campaign->name;
} else {
    echo "No active campaign";
}
```

---

## Error Responses

### No Active Campaign
```json
{
  "status": 1,
  "data": {
    "campaign": null,
    "message": "No active campaign at the moment"
  }
}
```

### Campaign Not Found
```json
{
  "status": 0,
  "message": "Campaign not found"
}
```

### Campaign Expired
```json
{
  "status": 0,
  "message": "This campaign is no longer active"
}
```

### Server Error
```json
{
  "status": 0,
  "message": "Failed to fetch campaign: Error details"
}
```

---

## Data Seeding

### Run Seeder
```bash
# Seed only brand campaigns
php artisan db:seed --class=BrandCampaignSeeder

# Or include in main seeder
php artisan db:seed
```

### Seeded Data
1. **Pure Goodness Sunflower Oil** (CURRENTLY ACTIVE)
   - Status: Active
   - Duration: Today → 30 days
   - Type: Brand Promotion

2. **Seasonal Cooking Oil Collection** (FUTURE - starts day 31)
   - Status: Active (scheduled)
   - Duration: Day 31 → Day 61
   - Type: Seasonal

3. **Flash Sale - Premium Oils** (FUTURE - starts day 62)
   - Status: Active (scheduled)
   - Duration: Day 62 → Day 63 (24-hour sale)
   - Type: Flash Sale

4. **Previous Season Campaign** (PAST - inactive)
   - Status: Inactive
   - Ended: 30+ days ago
   - For testing expired campaign handling

---

## Integration Examples

### Example 1: Display Current Campaign on Homepage
```javascript
// Fetch current campaign
fetch('/api/customer/brand-campaigns')
  .then(res => res.json())
  .then(data => {
    if (data.data.campaign) {
      displayCampaign(data.data.campaign);
    } else {
      hideCampaignSection();
    }
  });
```

### Example 2: Display Campaign with Products
```javascript
// Fetch campaign details with products
fetch('/api/customer/brand-campaigns/details')
  .then(res => res.json())
  .then(data => {
    const { campaign, products } = data.data;
    displayCampaignBanners(campaign.banners);
    displayProducts(products);
  });
```

### Example 3: Get Specific Campaign
```javascript
// Fetch campaign by ID
fetch('/api/customer/brand-campaigns/1')
  .then(res => res.json())
  .then(data => {
    const { campaign, products, days_until_expiry } = data.data;
    console.log(`Campaign expires in ${days_until_expiry} days`);
  });
```

---

## Migration File
Location: `database/migrations/2026_01_13_000001_create_brand_campaigns_table.php`

## Model File
Location: `app/Models/BrandCampaign.php`

## Controller File
Location: `app/Http/Controllers/API/Customer/BrandCampaignController.php`

## Seeder File
Location: `database/seeders/BrandCampaignSeeder.php`

## Routes File
Location: `routes/customer.php` (under `/api/customer/brand-campaigns` prefix)

---

## Future Enhancements
- Admin API for creating/editing campaigns
- Campaign analytics and view tracking
- A/B testing for banner variations
- Video embedding and lazy loading
- Regional campaign targeting
- Customer segment targeting
- Campaign performance reports
