# Qena Data Collection v1

This module is a controlled ingestion layer for public business data in Qena Governorate.

## What it does

- Imports CSV records into a staging table.
- Normalizes Arabic names, Egyptian mobile numbers, and URLs.
- Creates a deterministic fingerprint to prevent exact duplicate inserts.
- Calculates a 0–100 quality score.
- Detects likely duplicates by phone or name similarity.
- Keeps all collected records hidden from the public application until reviewed.
- Provides admin-only endpoints for review and duplicate resolution.

## Apply migration

```bash
cd apps/api
npm run prisma:migrate
```

## CSV columns

The importer accepts English or selected Arabic column names:

```csv
name,category,subcategory,city,area,village,address,phone,whatsapp,email,website,facebook,instagram,tiktok,google_maps_url,latitude,longitude,rating,review_count,external_id
```

Only `name` is required.

## Import

```bash
cd apps/api
npm run data:import -- \
  --file=./data/photographers-qena.csv \
  --category=photography \
  --area=قنا
```

The command returns:

```json
{
  "jobId": "...",
  "found": 100,
  "saved": 83,
  "duplicates": 14,
  "failed": 3
}
```

## Mount the admin router

In `src/server.ts`:

```ts
import { createDataCollectionRouter } from './data-collection/router';
```

After JSON middleware and before the global error handler:

```ts
app.use(
  '/api/admin/data-collection',
  requireAdmin,
  createDataCollectionRouter(prisma),
);
```

## Admin endpoints

- `GET /api/admin/data-collection/overview`
- `GET /api/admin/data-collection/records`
- `GET /api/admin/data-collection/duplicates`
- `PATCH /api/admin/data-collection/records/:id`
- `PATCH /api/admin/data-collection/duplicates/:id`
- `POST /api/admin/data-collection/jobs/manual`

All endpoints must remain behind `requireAdmin`.

## Important

This module does not bypass login pages, CAPTCHAs, robots rules, or platform access controls.
Use public data, official APIs, licensed data providers, and manual CSV exports.
