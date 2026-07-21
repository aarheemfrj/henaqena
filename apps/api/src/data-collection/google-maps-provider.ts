// Google Places API (New) — Text Search client.
// Docs reviewed 2026-07-21: https://developers.google.com/maps/documentation/places/web-service/text-search
// Endpoint: POST https://places.googleapis.com/v1/places:searchText
// Auth: X-Goog-Api-Key header. Fields: X-Goog-FieldMask header (required, no default fields).
// Pagination: pageSize max 20, nextPageToken, hard cap of 60 results total across pages.

const GOOGLE_MAPS_TEXT_SEARCH_URL = 'https://places.googleapis.com/v1/places:searchText';

const FIELD_MASK = [
  'places.id',
  'places.displayName',
  'places.formattedAddress',
  'places.location',
  'places.internationalPhoneNumber',
  'places.nationalPhoneNumber',
  'places.websiteUri',
  'places.googleMapsUri',
  'places.rating',
  'places.userRatingCount',
  'places.regularOpeningHours',
  'places.primaryType',
  'places.types',
  'nextPageToken',
].join(',');

export const GOOGLE_PLACES_MAX_PAGE_SIZE = 20;
export const GOOGLE_PLACES_MAX_TOTAL_RESULTS = 60; // documented hard cap across all pages
const REQUEST_TIMEOUT_MS = 10_000;
const MAX_RETRIES = 3;
const RETRY_BASE_DELAY_MS = 500;
const PAGE_TOKEN_DELAY_MS = 2000; // Google's nextPageToken needs a brief delay before it is valid
const MIN_REQUEST_INTERVAL_MS = 250; // simple self-throttle between outgoing requests

export class GoogleMapsQuotaError extends Error {}
export class GoogleMapsProviderError extends Error {}

export function isGoogleMapsConfigured(): boolean {
  return process.env.GOOGLE_MAPS_PROVIDER_ENABLED === 'true' && Boolean(process.env.GOOGLE_MAPS_API_KEY?.trim());
}

export function composeSearchQuery(params: { category: string; area: string; query?: string | null }): string {
  return [params.category, params.area, params.query, 'قنا']
    .map((part) => part?.trim())
    .filter((part): part is string => Boolean(part))
    .join(' ');
}

export type GooglePlaceResult = {
  id: string;
  displayName?: { text?: string };
  formattedAddress?: string;
  location?: { latitude?: number; longitude?: number };
  internationalPhoneNumber?: string;
  nationalPhoneNumber?: string;
  websiteUri?: string;
  googleMapsUri?: string;
  rating?: number;
  userRatingCount?: number;
  regularOpeningHours?: unknown;
  primaryType?: string;
  types?: string[];
};

type TextSearchResponse = { places?: GooglePlaceResult[]; nextPageToken?: string };

let lastRequestAt = 0;
async function throttle(): Promise<void> {
  const wait = lastRequestAt + MIN_REQUEST_INTERVAL_MS - Date.now();
  if (wait > 0) await new Promise((resolve) => setTimeout(resolve, wait));
  lastRequestAt = Date.now();
}

async function fetchWithTimeout(url: string, init: RequestInit): Promise<Response> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);
  try {
    return await fetch(url, { ...init, signal: controller.signal });
  } finally {
    clearTimeout(timer);
  }
}

async function textSearchPage(apiKey: string, body: Record<string, unknown>): Promise<TextSearchResponse> {
  let lastError: unknown;

  for (let attempt = 0; attempt < MAX_RETRIES; attempt += 1) {
    await throttle();
    try {
      const response = await fetchWithTimeout(GOOGLE_MAPS_TEXT_SEARCH_URL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': apiKey,
          'X-Goog-FieldMask': FIELD_MASK,
        },
        body: JSON.stringify(body),
      });

      if (response.status === 429) {
        throw new GoogleMapsQuotaError('تم تجاوز الحد المسموح لطلبات Google Places API (quota)');
      }

      if (!response.ok) {
        // Never log the raw response body: it may echo request params or key-adjacent diagnostics.
        throw new GoogleMapsProviderError(`Google Places API request failed with status ${response.status}`);
      }

      return await response.json() as TextSearchResponse;
    } catch (error) {
      if (error instanceof GoogleMapsQuotaError) throw error;
      lastError = error;
      if (attempt < MAX_RETRIES - 1) {
        await new Promise((resolve) => setTimeout(resolve, RETRY_BASE_DELAY_MS * 2 ** attempt));
      }
    }
  }

  throw lastError instanceof Error ? lastError : new GoogleMapsProviderError('تعذر الاتصال بمزود Google Places');
}

/**
 * Yields one page at a time so a caller can persist results incrementally —
 * if a later page fails (e.g. quota exhausted), everything already yielded
 * is safely saved rather than lost.
 */
export async function* iterateGooglePlaces(params: { textQuery: string; limit: number }): AsyncGenerator<GooglePlaceResult[]> {
  if (!isGoogleMapsConfigured()) throw new GoogleMapsProviderError('Google Maps provider is not configured');
  const apiKey = process.env.GOOGLE_MAPS_API_KEY as string;

  const targetCount = Math.min(Math.max(1, params.limit), GOOGLE_PLACES_MAX_TOTAL_RESULTS);
  let collected = 0;
  let pageToken: string | undefined;

  do {
    const pageSize = Math.min(GOOGLE_PLACES_MAX_PAGE_SIZE, targetCount - collected);
    const body: Record<string, unknown> = { textQuery: params.textQuery, pageSize };
    if (pageToken) body.pageToken = pageToken;

    const page = await textSearchPage(apiKey, body);
    const places = (page.places ?? []).slice(0, targetCount - collected);
    collected += places.length;
    yield places;

    pageToken = page.nextPageToken;
    if (pageToken && collected < targetCount) {
      await new Promise((resolve) => setTimeout(resolve, PAGE_TOKEN_DELAY_MS));
    }
  } while (pageToken && collected < targetCount);
}

/** Convenience wrapper over {@link iterateGooglePlaces} for callers that just want the full list. */
export async function searchGooglePlaces(params: { textQuery: string; limit: number }): Promise<GooglePlaceResult[]> {
  const results: GooglePlaceResult[] = [];
  for await (const page of iterateGooglePlaces(params)) results.push(...page);
  return results;
}

export function buildGoogleMapsUrl(place: GooglePlaceResult): string {
  if (place.googleMapsUri) return place.googleMapsUri;
  return `https://www.google.com/maps/place/?q=place_id:${encodeURIComponent(place.id)}`;
}
