-- ========================================
-- Create Test Admin User - SQL Script
-- ========================================
-- This script duplicates the admin with ID=1 with new credentials
-- New credentials: testing@gmail.com / Test@123456
-- ========================================

-- Step 1: Insert new test admin (this will get a new ID automatically)
-- The password hash for 'Test@123456' using Laravel's bcrypt
-- You may need to generate a new hash if you want a different password
INSERT INTO admins (username, email, password, role_id, created_by, forgot_password_code, fcm_id, created_at, updated_at)
SELECT
    'testadmin' as username,
    'testing@gmail.com' as email,
    '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi' as password, -- This is bcrypt hash for 'password'
    role_id,
    id as created_by,
    NULL as forgot_password_code,
    NULL as fcm_id,
    NOW() as created_at,
    NOW() as updated_at
FROM admins
WHERE id = 1
LIMIT 1;

-- Get the newly created admin ID (you'll need to note this)
SET @new_admin_id = LAST_INSERT_ID();

-- Step 2: Copy role assignments from model_has_roles table
INSERT INTO model_has_roles (role_id, model_type, model_id)
SELECT
    role_id,
    'App\\Models\\Admin' as model_type,
    @new_admin_id as model_id
FROM model_has_roles
WHERE model_type = 'App\\Models\\Admin'
AND model_id = (SELECT id FROM admins WHERE id = 1 LIMIT 1);

-- Step 3: Copy direct permission assignments from model_has_permissions table (if any)
INSERT INTO model_has_permissions (permission_id, model_type, model_id)
SELECT
    permission_id,
    'App\\Models\\Admin' as model_type,
    @new_admin_id as model_id
FROM model_has_permissions
WHERE model_type = 'App\\Models\\Admin'
AND model_id = (SELECT id FROM admins WHERE id = 1 LIMIT 1);

-- Verify the new admin was created
SELECT id, username, email, role_id, created_by, created_at
FROM admins
WHERE email = 'testing@gmail.com';

-- ========================================
-- IMPORTANT NOTES:
-- ========================================
-- 1. The password hash provided is for the word 'password' - you MUST change this
-- 2. To generate a proper hash for 'Test@123456', run this in Laravel tinker:
--    php artisan tinker
--    >>> echo bcrypt('Test@123456');
--    Then copy that hash and replace the password value above
--
-- 3. New credentials will be:
--    Email: testing@gmail.com
--    Password: Test@123456 (after you update the hash)
--
-- 4. To run this script:
--    mysql -u your_username -p your_database_name < create_test_admin.sql
--
-- 5. Or run it in your MySQL client or phpMyAdmin
-- ========================================


-- ========================================
-- ALTERNATIVE: Simpler single query approach
-- ========================================
-- If you want to run commands one by one in phpMyAdmin or MySQL Workbench:

/*
-- First, generate the password hash using Laravel
-- Run in terminal: php artisan tinker
-- Then run: echo bcrypt('Test@123456');
-- Copy the output hash

-- Then run this query (replace YOUR_HASH_HERE with the actual hash):
-- This will duplicate the admin with ID=1
INSERT INTO admins (username, email, password, role_id, created_by, created_at, updated_at)
SELECT
    'testadmin',
    'testing@gmail.com',
    'YOUR_HASH_HERE',
    role_id,
    id,
    NOW(),
    NOW()
FROM admins
WHERE id = 1
LIMIT 1;

-- Then get the new admin's ID:
SELECT id FROM admins WHERE email = 'testing@gmail.com';

-- Then copy the role assignments (replace NEW_ADMIN_ID with the ID from above):
INSERT INTO model_has_roles (role_id, model_type, model_id)
SELECT
    role_id,
    'App\\Models\\Admin',
    NEW_ADMIN_ID
FROM model_has_roles
WHERE model_type = 'App\\Models\\Admin'
AND model_id = 1;

-- And copy permission assignments (replace NEW_ADMIN_ID with the ID from above):
INSERT INTO model_has_permissions (permission_id, model_type, model_id)
SELECT
    permission_id,
    'App\\Models\\Admin',
    NEW_ADMIN_ID
FROM model_has_permissions
WHERE model_type = 'App\\Models\\Admin'
AND model_id = 1;
*/
