# Sprint 2C — Location Intelligence & Maps

**Status:** Pre-implementation audit
**Scope:** Internal Qena map, location permissions, map visibility, distance and external directions. No new product modules.
**Baseline:** `v0.3-search`

## Pre-implementation audit

### Existing implementation

- Flutter uses `flutter_map` with OpenStreetMap tiles for the internal map. `google_maps_flutter` is installed for optional credential-dependent integrations, while external directions use the existing platform action fallback.
- `ProviderMapPage` receives a provider future from the directory and renders a map plus a list. Provider labels and category-colored markers already exist.
- `InternalQenaMap` supports zoom controls, recentering, a user-position stream after recenter, route polylines and camera fitting for a route.
- Location permission is requested only when the map/distance feature is used, but the current flow does not distinguish service-disabled, timeout, denied-forever or unavailable states consistently and can silently fall back to Qena.
- Providers without coordinates currently receive synthetic area-center fallback pins. This is unsafe because the visible marker can misrepresent a real place.
- Map results are loaded through the normal `/api/providers` directory query. There is no bounded map-marker endpoint, viewport request, marker payload cap or stale viewport request guard.
- Distance sorting in the API currently uses squared coordinate differences instead of one shared Haversine calculation. Flutter uses `Geolocator.distanceBetween` independently.
- There is no clustering dependency. The safe existing option is bounded viewport filtering/deduplication; adding a clustering package is deferred.
- Admin provider editing already exposes latitude/longitude. The admin overview has coordinate-quality counts, but no dedicated map-quality report endpoint.

### Risks and gaps found

1. Synthetic fallback coordinates can place a provider away from its actual address.
2. Public map loading can read a broad directory page rather than a bounded, lightweight marker payload.
3. Invalid/non-finite coordinate query values are not rejected consistently.
4. Location errors are not actionable: the user is not offered app/location settings for denied-forever or disabled services.
5. Marker identity/duplicate handling is implicit rather than explicit.
6. Route fitting and user-following exist, but map state can jump when location is resolved and there is no dedicated stale-request protection for future viewport loading.
7. No taxonomy/coordinate audit report is exposed to admin beyond existing summary counts.

### Scope decision

This sprint will improve the existing map without replacing its SDK or adding a taxonomy migration. It will add a bounded map-marker API, shared coordinate/distance validation, safe marker rendering and actionable location states. Clustering, offline tiles, internal turn-by-turn navigation and paid directions APIs remain deferred.

## Deferred items (must not be treated as completed)

- Marker clustering package and server-side spatial indexes.
- Offline map tiles and turn-by-turn navigation.
- Google Maps/Places production credential and physical-device verification.
- Automatic correction of suspicious coordinates.
- Category parent/child relations and any Prisma migration for them.

Implementation and validation stages will be appended below with separate commit boundaries.
