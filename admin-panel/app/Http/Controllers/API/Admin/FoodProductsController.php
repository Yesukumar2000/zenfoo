<?php

namespace App\Http\Controllers\API\Admin;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\City;
use App\Models\Seller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class FoodProductsController extends Controller
{
    /**
     * Food store ID (store_id = 15)
     */
    const STORE_ID = 15;

    /**
     * Get Food products scoped to store_id = 15 with optional geo-boundary zone filter.
     *
     * Zone filter flow:
     *   1. Fetch all active sellers for this food store.
     *   2. Filter sellers by city boundary (polygon / radius) using lat_long.
     *   3. Use the resulting seller IDs as a whereIn on p.seller_id BEFORE pagination,
     *      so counts and offsets are always accurate.
     */
    public function getProducts(Request $request)
    {
        $limit  = $request->input('per_page');
        $offset = (($request->input('page')) - 1) * $limit;
        $filter = $request->input('filter', '');

        // ---------------------------------------------------------------
        // 1. Zone / City filter — resolve seller IDs in the requested zone
        // ---------------------------------------------------------------
        $sellerIdsInZone = null; // null = no zone filter

        if ($request->filled('city_id')) {
            $storeSellers = Seller::where('store_id', self::STORE_ID)
                ->where('status', 1)
                ->select('id', 'lat_long')
                ->get();

            if ($request->city_id === 'other') {
                $allCities       = City::all();
                $sellerIdsInZone = $storeSellers->filter(function ($seller) use ($allCities) {
                    return !$this->isInAnyCity($seller, $allCities);
                })->pluck('id')->toArray();
            } else {
                $city = City::find($request->city_id);
                if ($city) {
                    $sellerIdsInZone = $storeSellers->filter(function ($seller) use ($city) {
                        return $this->isSellerInCity($seller, $city);
                    })->pluck('id')->toArray();
                }
            }
        }

        // ---------------------------------------------------------------
        // 2. Categories for this store (via category_group_store chain)
        // ---------------------------------------------------------------
        $categoryGroupIds = DB::table('category_group_store')
            ->where('store_id', self::STORE_ID)
            ->pluck('category_group_id')
            ->unique()
            ->toArray();

        $rawSubCategoryIds = DB::table('sub_category_groups')
            ->whereIn('category_group_id', $categoryGroupIds)
            ->pluck('subcategory_ids')
            ->toArray();

        $categoryIds = collect($rawSubCategoryIds)
            ->flatMap(fn($v) => explode(',', $v))
            ->map(fn($id) => (int) trim($id))
            ->unique()
            ->values()
            ->toArray();

        $categories = Category::where('status', 1)
            ->whereIn('id', $categoryIds)
            ->select('id', 'name')
            ->orderBy('id', 'DESC')
            ->get()
            ->makeHidden(['image_url', 'has_child', 'has_active_child'])
            ->toArray();

        // ---------------------------------------------------------------
        // 3. Seller dropdown list (filtered by zone when applicable)
        // ---------------------------------------------------------------
        $sellersQuery = Seller::where('store_id', self::STORE_ID)
            ->where('status', 1);

        if ($sellerIdsInZone !== null) {
            $sellersQuery->whereIn('id', $sellerIdsInZone);
        }

        $sellers = $sellersQuery
            ->select('id', 'name')
            ->orderBy('id', 'DESC')
            ->get()
            ->makeHidden(['logo_url', 'national_identity_card_url', 'address_proof_url', 'categories_array'])
            ->toArray();

        // ---------------------------------------------------------------
        // 4. Build products query
        // ---------------------------------------------------------------
        $where   = [];
        $where[] = ['p.store_id', '=', self::STORE_ID];

        if (isset($request->is_approved) && $request->is_approved !== '') {
            $where[] = ['p.is_approved', '=', $request->is_approved];
        }

        if (isset($request->seller) && $request->seller !== '') {
            $where[] = ['p.seller_id', '=', $request->seller];
        }

        if (isset($request->category) && $request->category !== '') {
            $where[] = ['p.category_id', '=', $request->category];
        }

        $products = DB::table('products as p')
            ->select(
                'p.id as id', 'p.id as product_id', 'p.name', 'p.seller_id', 'p.status',
                'p.tax_id', 'p.image', 's.name as seller_name', 's.id as seller_id',
                'p.indicator', 'p.is_approved', 'p.manufacturer', 'p.made_in',
                'p.return_status', 'p.cancelable_status', 'p.till_status',
                'pv.id as product_variant_id', 'pv.price', 'pv.discounted_price',
                'pv.measurement', 'pv.status as pv_status', 'pv.stock', 'pv.stock_unit_id',
                'u.short_code',
                DB::raw('(select short_code from units where units.id = pv.stock_unit_id) as stock_unit')
            )
            ->join('sellers as s', 'p.seller_id', '=', 's.id') // INNER JOIN — excludes orphaned products (seller_id not in sellers table)
            ->join('product_variants as pv', 'p.id', '=', 'pv.product_id')
            ->join('units as u', 'pv.stock_unit_id', '=', 'u.id');

        foreach ($where as $condition) {
            $products->where($condition[0], $condition[1], $condition[2]);
        }

        // Apply zone filter BEFORE pagination so totals are correct
        if ($sellerIdsInZone !== null) {
            $products->whereIn('p.seller_id', $sellerIdsInZone);
        }

        $products->orderBy('pv.id', 'desc');

        if ($filter) {
            $columns = ['p.id', 'pv.id', 'p.name', 's.name', 'pv.price', 'pv.discounted_price', 'pv.measurement', 'pv.stock'];
            $products->where(function ($query) use ($filter, $columns) {
                foreach ($columns as $column) {
                    $query->orWhere($column, 'like', "%{$filter}%");
                }
            });
        }

        $total = $products->count();

        if (isset($limit)) {
            $products->limit($limit)->offset($offset);
        }

        $products = $products->get();

        return CommonHelper::responseWithData([
            'categories' => $categories,
            'sellers'    => $sellers,
            'products'   => $products,
        ], $total);
    }

    /**
     * Get categories for a given seller directly from the categories table
     * using the seller_id column.
     */
    public function getSellerCategories(Request $request)
    {
        $categories = Category::where('status', 1)
            ->where('seller_id', $request->seller_id)
            ->select('id', 'name')
            ->orderBy('name', 'ASC')
            ->get()
            ->makeHidden(['image_url', 'has_child', 'has_active_child'])
            ->toArray();

        return CommonHelper::responseWithData($categories);
    }

    // ===================================================================
    // Geo helpers — identical to SellerApiController
    // ===================================================================

    private function isSellerInCity($seller, $city): bool
    {
        if (empty($seller->lat_long)) {
            return false;
        }

        $parts = explode(',', $seller->lat_long);
        if (count($parts) < 2) {
            return false;
        }

        $lat = floatval(trim($parts[0]));
        $lng = floatval(trim($parts[1]));

        if ($city->geolocation_type === 'polygon') {
            $polygon = is_string($city->boundary_points)
                ? json_decode($city->boundary_points, true)
                : $city->boundary_points;

            if (empty($polygon) || !is_array($polygon)) {
                return false;
            }

            return $this->isPointInPolygon($lat, $lng, $polygon);

        } elseif ($city->geolocation_type === 'radius') {
            $distance = $this->haversineDistance(
                $lat, $lng,
                floatval($city->latitude),
                floatval($city->longitude)
            );
            return $distance <= floatval($city->radius);
        }

        return false;
    }

    private function isInAnyCity($seller, $allCities): bool
    {
        if (empty($seller->lat_long)) {
            return false;
        }

        foreach ($allCities as $city) {
            if ($this->isSellerInCity($seller, $city)) {
                return true;
            }
        }

        return false;
    }

    private function haversineDistance(float $lat1, float $lng1, float $lat2, float $lng2): float
    {
        $R    = 6371; // Earth radius in km
        $dLat = deg2rad($lat2 - $lat1);
        $dLng = deg2rad($lng2 - $lng1);
        $a    = sin($dLat / 2) ** 2
              + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLng / 2) ** 2;
        return $R * 2 * atan2(sqrt($a), sqrt(1 - $a));
    }

    private function isPointInPolygon(float $lat, float $lng, array $polygon): bool
    {
        $count  = count($polygon);
        $inside = false;
        $j      = $count - 1;

        for ($i = 0; $i < $count; $j = $i++) {
            $xi = floatval($polygon[$i]['lat']);
            $yi = floatval($polygon[$i]['lng']);
            $xj = floatval($polygon[$j]['lat']);
            $yj = floatval($polygon[$j]['lng']);

            if ((($yi > $lng) !== ($yj > $lng)) &&
                ($lat < ($xj - $xi) * ($lng - $yi) / ($yj - $yi) + $xi)) {
                $inside = !$inside;
            }
        }

        return $inside;
    }
}
