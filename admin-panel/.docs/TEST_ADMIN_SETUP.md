# Test Admin User Setup

This document explains how to create a duplicate admin user for testing purposes.

## New Test Admin Credentials

```
Email: testing@gmail.com
Password: Test@123456
```

## Option 1: Using Laravel Migration (Recommended)

This is the easiest and safest method:

```bash
# Run the migration
php artisan migrate

# Or if you want to run only this specific migration
php artisan migrate --path=/database/migrations/2026_02_10_120000_create_test_admin_user.php
```

The migration will:
- Find the admin user with ID = 1
- Create a new admin with email `testing@gmail.com`
- Copy all roles and permissions from that admin
- Set the password to `Test@123456`

### To Rollback (Remove Test Admin)

```bash
php artisan migrate:rollback --step=1
```

## Option 2: Using Direct SQL Commands

If you prefer to use SQL directly:

### Step 1: Generate Password Hash

First, generate the password hash for `Test@123456`:

```bash
php artisan tinker
```

Then in tinker:
```php
echo bcrypt('Test@123456');
```

Copy the output hash.

### Step 2: Run SQL Commands

Open your database client (phpMyAdmin, MySQL Workbench, etc.) and run:

```sql
-- Replace YOUR_HASH_HERE with the hash you generated above
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
```

### Step 3: Get the New Admin ID

```sql
SELECT id FROM admins WHERE email = 'testing@gmail.com';
```

Note this ID (let's say it's `123` for this example).

### Step 4: Copy Role Assignments

```sql
-- Replace 123 with your actual new admin ID
INSERT INTO model_has_roles (role_id, model_type, model_id)
SELECT
    role_id,
    'App\\Models\\Admin',
    123
FROM model_has_roles
WHERE model_type = 'App\\Models\\Admin'
AND model_id = 1;
```

### Step 5: Copy Permission Assignments

```sql
-- Replace 123 with your actual new admin ID
INSERT INTO model_has_permissions (permission_id, model_type, model_id)
SELECT
    permission_id,
    'App\\Models\\Admin',
    123
FROM model_has_permissions
WHERE model_type = 'App\\Models\\Admin'
AND model_id = 1;
```

## Verification

After creating the test admin, verify by:

1. Logging in with the new credentials:
   - Email: `testing@gmail.com`
   - Password: `Test@123456`

2. Check that all permissions match the original admin account

3. Verify you can access all the same features and sections

## Important Notes

- The test admin will have the **exact same permissions** as the admin with ID=1
- The `created_by` field will reference the original admin user (ID=1)
- This is a completely separate user account - changes to one won't affect the other
- You can safely delete this test admin anytime without affecting the original admin

## Troubleshooting

### Migration fails with "Admin with ID=1 not found"
Make sure there is an admin account with ID=1 in the admins table before running the migration.

### Login fails
Make sure you're using the correct credentials:
- Email: `testing@gmail.com` (not testadmin@gmail.com)
- Password: `Test@123456` (case sensitive)

### Permissions not working
Make sure both the `model_has_roles` and `model_has_permissions` tables were populated correctly.

## For Testing Team

This test admin account has been created specifically for testing purposes:
- Use it for all testing activities
- Don't share these credentials outside the testing team
- Don't modify the original admin account (ID=1)
- Report any permission issues immediately
