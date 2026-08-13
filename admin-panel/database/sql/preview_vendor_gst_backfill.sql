-- =========================================================================
-- Preview the rows that the vendor_gst_percent backfill WOULD touch.
--
-- This is a SELECT-only script. Run it in phpMyAdmin (or any SQL client)
-- and inspect the output BEFORE running the UPDATE statement below.
--
-- Outputs columns:
--   seller_id, store_id, store_name, category, current_pct, new_pct
--
-- "current_pct" is what is already stored on the seller row (NULL if it
-- has never been set). "new_pct" is the value the backfill would write,
-- pulled from the matching Vendor GST Configurations setting.
--
-- Categories with no admin-configured rate appear as new_pct = NULL and
-- will be left untouched by the UPDATE.
-- =========================================================================

SELECT
    s.id   AS seller_id,
    s.store_id,
    st.name AS store_name,
    CASE
        WHEN st.is_meat       = 1 THEN 'Chicken & Meat'
        WHEN st.is_food       = 1 THEN 'Food'
        WHEN st.is_super_mart = 1 THEN 'Super Mart'
        WHEN st.is_vegetable  = 1 THEN 'Vegetables & Fruits'
        ELSE '(no category flag)'
    END AS category,
    s.vendor_gst_percent AS current_pct,
    CASE
        WHEN st.is_meat       = 1 THEN (SELECT value FROM settings WHERE variable = 'vendor_gst_chicken_meat')
        WHEN st.is_food       = 1 THEN (SELECT value FROM settings WHERE variable = 'vendor_gst_food')
        WHEN st.is_super_mart = 1 THEN (SELECT value FROM settings WHERE variable = 'vendor_gst_super_mart')
        WHEN st.is_vegetable  = 1 THEN (SELECT value FROM settings WHERE variable = 'vendor_gst_vegetables_fruits')
    END AS new_pct
FROM sellers s
INNER JOIN stores  st ON st.id = s.store_id
WHERE s.vendor_gst_percent IS NULL
ORDER BY s.id;

-- =========================================================================
-- ONLY run this UPDATE after reviewing the SELECT above and confirming the
-- new_pct values look right. The UPDATE will not change rows where the
-- store has no category flag or where the matching setting is missing.
-- =========================================================================

-- UPDATE sellers s
-- INNER JOIN stores st ON st.id = s.store_id
-- SET s.vendor_gst_percent = (
--     CASE
--         WHEN st.is_meat       = 1 THEN (SELECT value FROM settings WHERE variable = 'vendor_gst_chicken_meat')
--         WHEN st.is_food       = 1 THEN (SELECT value FROM settings WHERE variable = 'vendor_gst_food')
--         WHEN st.is_super_mart = 1 THEN (SELECT value FROM settings WHERE variable = 'vendor_gst_super_mart')
--         WHEN st.is_vegetable  = 1 THEN (SELECT value FROM settings WHERE variable = 'vendor_gst_vegetables_fruits')
--     END
-- )
-- WHERE s.vendor_gst_percent IS NULL;

-- =========================================================================
-- After the UPDATE, verify by re-running the SELECT above; every row
-- previously listed should now have current_pct populated.
-- =========================================================================
