# zenfoo

Monorepo containing the Zenfoo platform.

## Layout

| Folder | Stack | Description |
| --- | --- | --- |
| [`admin-panel/`](admin-panel/) | Laravel (PHP) | Admin / backend panel |
| [`customer-app/`](customer-app/) | Flutter | Customer mobile app |
| [`partner-app/`](partner-app/) | Flutter | Restaurant / vendor partner app |
| [`delivery-partner-app/`](delivery-partner-app/) | Flutter | Delivery partner app |

## Setup

Dependencies are not committed — install them per project.

```bash
# admin-panel
cd admin-panel && composer install && cp .env.example .env && php artisan key:generate

# any Flutter app
cd customer-app && flutter pub get
```

## Release builds (Android)

Signing material is **not** in this repo. To build a signed release, get the
keystore and passwords from the project owner and create `android/key.properties`
in the app you are building, following [`key.properties.example`](key.properties.example).

Never commit `*.jks` or `key.properties` — this repository is public.
