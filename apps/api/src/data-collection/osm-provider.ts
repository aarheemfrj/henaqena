// OpenStreetMap collection — completely free, no API key or billing needed.
//
// Nominatim (geocoding) usage policy reviewed 2026-07-21:
// https://operations.osmfoundation.org/policies/nominatim/
//   - hard cap of 1 request/second, must self-throttle
//   - must send a descriptive User-Agent identifying the app (generic defaults rejected)
//   - no autocomplete/bulk grid queries — this module geocodes an area name once per job
//
// Overpass API usage policy reviewed 2026-07-21:
// https://wiki.openstreetmap.org/wiki/Overpass_API
//   - public endpoint https://overpass-api.de/api/interpreter
//   - fair use: stay under ~10,000 queries/day and ~1GB/day
//   - must send an identifying User-Agent

const USER_AGENT = 'HenaQenaDataCollection/1.0 (+https://henaqena.maalsoft.com)';
const NOMINATIM_URL = 'https://nominatim.openstreetmap.org/search';
const OVERPASS_URL = 'https://overpass-api.de/api/interpreter';
const REQUEST_TIMEOUT_MS = 15_000;
const MAX_RETRIES = 3;
const RETRY_BASE_DELAY_MS = 800;
const NOMINATIM_MIN_INTERVAL_MS = 1100; // stays under Nominatim's 1 req/sec cap
const OVERPASS_MIN_INTERVAL_MS = 1000;
const OVERPASS_MAX_RESULTS = 200;

export class OsmProviderError extends Error {}

// Arabic category label (as used across the app) -> candidate OSM tags to search.
// Multiple tags per category since OSM taggers use different conventions.
const CATEGORY_TAGS: Record<string, Array<[string, string]>> = {
  'مطاعم': [['amenity', 'restaurant']],
  'كافيهات': [['amenity', 'cafe']],
  'صيدليات': [['amenity', 'pharmacy']],
  'مستشفيات': [['amenity', 'hospital']],
  'عيادات': [['amenity', 'clinic'], ['healthcare', 'clinic']],
  'أطباء': [['amenity', 'doctors']],
  'معامل تحاليل': [['healthcare', 'laboratory']],
  'مراكز أشعة': [['healthcare', 'radiology'], ['healthcare', 'diagnostic_centre']],
  'استوديوهات تصوير': [['shop', 'photo'], ['craft', 'photographer']],
  'قاعات أفراح': [['amenity', 'events_venue'], ['amenity', 'community_centre']],
  'فنادق': [['tourism', 'hotel']],
  'شقق فندقية': [['tourism', 'apartment'], ['tourism', 'guest_house']],
  'سوبر ماركت': [['shop', 'supermarket']],
  'مخابز': [['shop', 'bakery']],
  'حلواني': [['shop', 'confectionery'], ['shop', 'pastry']],
  'محلات ملابس': [['shop', 'clothes']],
  'محلات أحذية': [['shop', 'shoes']],
  'محلات موبايلات': [['shop', 'mobile_phone']],
  'صيانة موبايلات': [['shop', 'mobile_phone'], ['craft', 'electronics_repair']],
  'أجهزة كهربائية': [['shop', 'electronics'], ['shop', 'appliance']],
  'أثاث': [['shop', 'furniture']],
  'أدوات منزلية': [['shop', 'houseware']],
  'شركات مقاولات': [['office', 'construction_company']],
  'تشطيبات وديكور': [['shop', 'doityourself'], ['shop', 'interior_decoration']],
  'مكاتب عقارات': [['office', 'estate_agent']],
  'مكاتب محاماة': [['office', 'lawyer']],
  'محاسبون': [['office', 'accountant']],
  'مراكز تعليمية': [['office', 'educational_institution'], ['amenity', 'driving_school']],
  'حضانات': [['amenity', 'kindergarten']],
  'مدارس خاصة': [['amenity', 'school']],
  'جيمات': [['leisure', 'fitness_centre']],
  'صالونات تجميل': [['shop', 'beauty']],
  'حلاقين': [['shop', 'hairdresser']],
  'مغاسل سيارات': [['shop', 'car_wash'], ['amenity', 'car_wash']],
  'صيانة سيارات': [['shop', 'car_repair']],
  'قطع غيار سيارات': [['shop', 'car_parts']],
  'خدمات نقل': [['amenity', 'taxi']],
  'خدمات منزلية': [['craft', 'cleaning']],
};

export function categoryToOsmTags(category: string): Array<[string, string]> {
  return CATEGORY_TAGS[category] ?? [];
}

export function isCategoryMappedToOsm(category: string): boolean {
  return categoryToOsmTags(category).length > 0;
}

let lastNominatimRequestAt = 0;
async function throttleNominatim(): Promise<void> {
  const wait = lastNominatimRequestAt + NOMINATIM_MIN_INTERVAL_MS - Date.now();
  if (wait > 0) await new Promise((resolve) => setTimeout(resolve, wait));
  lastNominatimRequestAt = Date.now();
}

let lastOverpassRequestAt = 0;
async function throttleOverpass(): Promise<void> {
  const wait = lastOverpassRequestAt + OVERPASS_MIN_INTERVAL_MS - Date.now();
  if (wait > 0) await new Promise((resolve) => setTimeout(resolve, wait));
  lastOverpassRequestAt = Date.now();
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

async function withRetry<T>(fn: () => Promise<T>): Promise<T> {
  let lastError: unknown;
  for (let attempt = 0; attempt < MAX_RETRIES; attempt += 1) {
    try {
      return await fn();
    } catch (error) {
      lastError = error;
      if (attempt < MAX_RETRIES - 1) {
        await new Promise((resolve) => setTimeout(resolve, RETRY_BASE_DELAY_MS * 2 ** attempt));
      }
    }
  }
  throw lastError instanceof Error ? lastError : new OsmProviderError('تعذر الاتصال بمزود OpenStreetMap');
}

export type GeocodedArea = { lat: number; lon: number; displayName: string };

/** Geocodes an area name once — never used for autocomplete or bulk/grid queries. */
export async function geocodeArea(params: { area: string; city?: string | null }): Promise<GeocodedArea | null> {
  const query = [params.area, params.city ?? 'قنا', 'مصر'].filter(Boolean).join(', ');
  const url = new URL(NOMINATIM_URL);
  url.searchParams.set('format', 'json');
  url.searchParams.set('q', query);
  url.searchParams.set('limit', '1');
  url.searchParams.set('addressdetails', '0');

  await throttleNominatim();
  return withRetry(async () => {
    const response = await fetchWithTimeout(url.toString(), {
      headers: { 'User-Agent': USER_AGENT, 'Accept-Language': 'ar' },
    });
    if (!response.ok) throw new OsmProviderError(`Nominatim request failed with status ${response.status}`);
    const results = await response.json() as Array<{ lat: string; lon: string; display_name: string }>;
    if (!results.length) return null;
    return { lat: Number(results[0].lat), lon: Number(results[0].lon), displayName: results[0].display_name };
  });
}

export type OsmElement = {
  type: 'node' | 'way' | 'relation';
  id: number;
  lat?: number;
  lon?: number;
  center?: { lat: number; lon: number };
  tags?: Record<string, string>;
};

export async function searchOsmPlaces(params: {
  lat: number;
  lon: number;
  radiusMeters: number;
  tags: Array<[string, string]>;
  limit: number;
}): Promise<OsmElement[]> {
  if (!params.tags.length) throw new OsmProviderError('لا يوجد وسم OSM مطابق لهذه الفئة بعد');

  const filters = params.tags
    .map(([key, value]) => `
      node["${key}"="${value}"](around:${params.radiusMeters},${params.lat},${params.lon});
      way["${key}"="${value}"](around:${params.radiusMeters},${params.lat},${params.lon});
    `)
    .join('');

  const resultLimit = Math.min(Math.max(1, params.limit), OVERPASS_MAX_RESULTS);
  const query = `[out:json][timeout:25];(${filters});out center ${resultLimit};`;

  await throttleOverpass();
  return withRetry(async () => {
    const response = await fetchWithTimeout(OVERPASS_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'User-Agent': USER_AGENT },
      body: `data=${encodeURIComponent(query)}`,
    });
    if (response.status === 429) throw new OsmProviderError('تم تجاوز الحد المسموح لطلبات Overpass API');
    if (!response.ok) throw new OsmProviderError(`Overpass API request failed with status ${response.status}`);
    const body = await response.json() as { elements?: OsmElement[] };
    return (body.elements ?? []).slice(0, resultLimit);
  });
}

export function buildOsmId(element: OsmElement): string {
  return `${element.type}/${element.id}`;
}

export function buildOsmUrl(element: OsmElement): string {
  return `https://www.openstreetmap.org/${buildOsmId(element)}`;
}

export function osmElementCoordinates(element: OsmElement): { latitude: number | null; longitude: number | null } {
  if (typeof element.lat === 'number' && typeof element.lon === 'number') {
    return { latitude: element.lat, longitude: element.lon };
  }
  if (element.center) return { latitude: element.center.lat, longitude: element.center.lon };
  return { latitude: null, longitude: null };
}
