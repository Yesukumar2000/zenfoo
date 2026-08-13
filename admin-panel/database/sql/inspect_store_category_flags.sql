-- =========================================================================
-- Inspector: every store grouped by its current category-flag state, with
-- a suggested flag inferred from the store name.
--
-- This is a SELECT-only query. Run it in phpMyAdmin to decide which
-- stores need is_food / is_meat / is_vegetable / is_super_mart set.
--
-- The `suggested_flag` column is just a hint based on simple keyword
-- rules; use your judgement before applying.
-- =========================================================================

SELECT
    st.id AS store_id,
    st.name AS store_name,
    st.is_food,
    st.is_meat,
    st.is_vegetable,
    st.is_super_mart,
    CASE
        WHEN COALESCE(st.is_food, 0)       = 1
          OR COALESCE(st.is_meat, 0)       = 1
          OR COALESCE(st.is_vegetable, 0)  = 1
          OR COALESCE(st.is_super_mart, 0) = 1 THEN 'OK'
        WHEN LOWER(st.name) REGEXP 'meat|chicken|mutton|lamb|beef|pork|fish|camel' THEN 'set is_meat = 1'
        WHEN LOWER(st.name) REGEXP 'vegetable|fruit|\\bveg\\b'                     THEN 'set is_vegetable = 1'
        WHEN LOWER(st.name) REGEXP 'super ?mart|supermarket'                       THEN 'set is_super_mart = 1'
        WHEN LOWER(st.name) REGEXP 'food|restaurant|cuisine|kitchen'               THEN 'set is_food = 1'
        WHEN LOWER(st.name) REGEXP 'grocery|mart'                                  THEN 'AMBIGUOUS — pick is_super_mart or is_food'
        ELSE 'UNCLASSIFIED — pick a flag manually'
    END AS suggested_flag,
    (SELECT COUNT(*) FROM sellers WHERE store_id = st.id) AS seller_count
FROM stores st
ORDER BY suggested_flag, st.name, st.id;

-- =========================================================================
-- After deciding, apply per-row updates. Example templates — edit the
-- store_id and uncomment the flag you want:
-- =========================================================================

-- UPDATE stores SET is_food       = 1 WHERE id = <STORE_ID>;
-- UPDATE stores SET is_meat       = 1 WHERE id = <STORE_ID>;
-- UPDATE stores SET is_vegetable  = 1 WHERE id = <STORE_ID>;
-- UPDATE stores SET is_super_mart = 1 WHERE id = <STORE_ID>;
