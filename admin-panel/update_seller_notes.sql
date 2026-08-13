-- Add seller notes for seller_id 62 to various orders

-- Order 358 - Add note "Please pack apples carefully"
UPDATE orders
SET cart_metadata = JSON_SET(
    cart_metadata,
    '$.cart_info.seller_notes',
    JSON_OBJECT('62', 'Please pack apples carefully')
)
WHERE id = 358;

-- Order 351 - Add note "Extra fresh apples needed"
UPDATE orders
SET cart_metadata = JSON_SET(
    cart_metadata,
    '$.cart_info.seller_notes',
    JSON_OBJECT('62', 'Extra fresh apples needed')
)
WHERE id = 351;

-- Order 349 - Add note "No bruised fruits please"
UPDATE orders
SET cart_metadata = JSON_SET(
    cart_metadata,
    '$.cart_info.seller_notes',
    JSON_OBJECT('62', 'No bruised fruits please')
)
WHERE id = 349;

-- Order 348 - Add note "Pack in separate bags"
UPDATE orders
SET cart_metadata = JSON_SET(
    cart_metadata,
    '$.cart_info.seller_notes',
    JSON_OBJECT('62', 'Pack in separate bags')
)
WHERE id = 348;

-- Order 323 - Add note "Green apples preferred"
UPDATE orders
SET cart_metadata = JSON_SET(
    cart_metadata,
    '$.cart_info.seller_notes',
    JSON_OBJECT('62', 'Green apples preferred')
)
WHERE id = 323;

-- Order 321 - Add note "Need organic apples only"
UPDATE orders
SET cart_metadata = JSON_SET(
    cart_metadata,
    '$.cart_info.seller_notes',
    JSON_OBJECT('62', 'Need organic apples only')
)
WHERE id = 321;

-- Order 310 - Add note "Please add extra packaging"
UPDATE orders
SET cart_metadata = JSON_SET(
    cart_metadata,
    '$.cart_info.seller_notes',
    JSON_OBJECT('62', 'Please add extra packaging')
)
WHERE id = 310;

-- Order 307 - Add note "Deliver before 5 PM"
UPDATE orders
SET cart_metadata = JSON_SET(
    cart_metadata,
    '$.cart_info.seller_notes',
    JSON_OBJECT('62', 'Deliver before 5 PM')
)
WHERE id = 307;

-- Verify the updates
SELECT
    id,
    orders_id,
    JSON_EXTRACT(cart_metadata, '$.cart_info.seller_notes') as seller_notes
FROM orders
WHERE id IN (358, 351, 349, 348, 323, 321, 310, 307);
