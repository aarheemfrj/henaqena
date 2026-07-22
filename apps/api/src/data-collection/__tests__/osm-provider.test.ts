/**
 * geocodeArea/searchOsmPlaces are tested here with a mocked fetch. A separate,
 * manual live check against the real Nominatim/Overpass public endpoints was
 * also run during development (see PR description) — safe to do since neither
 * requires an API key, unlike the Google Maps provider tests.
 */
import {
  buildOsmId,
  buildOsmUrl,
  categoryToOsmTags,
  geocodeArea,
  isCategoryMappedToOsm,
  osmElementCoordinates,
  OsmProviderError,
  searchOsmPlaces,
  type OsmElement,
} from '../osm-provider';

const ORIGINAL_FETCH = global.fetch;

function mockFetchSequence(responses: Array<{ status: number; body: unknown }>) {
  let call = 0;
  global.fetch = jest.fn(async () => {
    const next = responses[Math.min(call, responses.length - 1)];
    call += 1;
    return {
      ok: next.status >= 200 && next.status < 300,
      status: next.status,
      json: async () => next.body,
    } as Response;
  }) as unknown as typeof fetch;
}

afterEach(() => {
  global.fetch = ORIGINAL_FETCH;
  jest.restoreAllMocks();
});

describe('categoryToOsmTags / isCategoryMappedToOsm', () => {
  it('maps a known Arabic category to OSM tags', () => {
    expect(categoryToOsmTags('مطاعم')).toEqual([['amenity', 'restaurant']]);
    expect(isCategoryMappedToOsm('مطاعم')).toBe(true);
  });

  it('supports categories with multiple candidate tags', () => {
    const tags = categoryToOsmTags('عيادات');
    expect(tags).toEqual([['amenity', 'clinic'], ['healthcare', 'clinic']]);
  });

  it('returns an empty list for an unmapped category', () => {
    expect(categoryToOsmTags('فئة غير موجودة')).toEqual([]);
    expect(isCategoryMappedToOsm('فئة غير موجودة')).toBe(false);
  });
});

describe('buildOsmId / buildOsmUrl', () => {
  it('builds a stable id and URL from an OSM element', () => {
    const element: OsmElement = { type: 'node', id: 123456 };
    expect(buildOsmId(element)).toBe('node/123456');
    expect(buildOsmUrl(element)).toBe('https://www.openstreetmap.org/node/123456');
  });

  it('works the same for way/relation elements', () => {
    expect(buildOsmId({ type: 'way', id: 42 })).toBe('way/42');
  });
});

describe('osmElementCoordinates', () => {
  it('prefers direct lat/lon (node) when present', () => {
    expect(osmElementCoordinates({ type: 'node', id: 1, lat: 26.16, lon: 32.72 }))
      .toEqual({ latitude: 26.16, longitude: 32.72 });
  });

  it('falls back to the center point (way/relation)', () => {
    expect(osmElementCoordinates({ type: 'way', id: 1, center: { lat: 26.1, lon: 32.7 } }))
      .toEqual({ latitude: 26.1, longitude: 32.7 });
  });

  it('returns nulls when neither is available', () => {
    expect(osmElementCoordinates({ type: 'relation', id: 1 })).toEqual({ latitude: null, longitude: null });
  });
});

describe('geocodeArea (mocked fetch)', () => {
  it('returns the first result on success', async () => {
    mockFetchSequence([{ status: 200, body: [{ lat: '26.1612', lon: '32.7167', display_name: 'قنا، مصر' }] }]);
    const result = await geocodeArea({ area: 'مدينة قنا' });
    expect(result).toEqual({ lat: 26.1612, lon: 32.7167, displayName: 'قنا، مصر' });
  }, 10000);

  it('returns null when Nominatim finds nothing', async () => {
    mockFetchSequence([{ status: 200, body: [] }]);
    const result = await geocodeArea({ area: 'مكان غير موجود تمامًا 12345' });
    expect(result).toBeNull();
  }, 10000);

  it('retries on transient failure and eventually succeeds', async () => {
    mockFetchSequence([
      { status: 500, body: {} },
      { status: 200, body: [{ lat: '1', lon: '2', display_name: 'x' }] },
    ]);
    const result = await geocodeArea({ area: 'قنا' });
    expect(result).toEqual({ lat: 1, lon: 2, displayName: 'x' });
    expect(global.fetch).toHaveBeenCalledTimes(2);
  }, 10000);
});

describe('searchOsmPlaces (mocked fetch)', () => {
  it('throws when no tags are provided (unmapped category)', async () => {
    await expect(searchOsmPlaces({ lat: 1, lon: 2, radiusMeters: 1000, tags: [], limit: 10 }))
      .rejects.toBeInstanceOf(OsmProviderError);
  });

  it('returns parsed elements up to the requested limit', async () => {
    mockFetchSequence([{ status: 200, body: { elements: Array.from({ length: 5 }, (_, i) => ({ type: 'node', id: i })) } }]);
    const results = await searchOsmPlaces({ lat: 26.16, lon: 32.72, radiusMeters: 5000, tags: [['amenity', 'restaurant']], limit: 3 });
    expect(results).toHaveLength(3);
  }, 10000);

  it('surfaces a clear error on rate limiting (429)', async () => {
    mockFetchSequence([{ status: 429, body: {} }]);
    await expect(searchOsmPlaces({ lat: 1, lon: 2, radiusMeters: 1000, tags: [['amenity', 'cafe']], limit: 5 }))
      .rejects.toThrow(/تجاوز الحد المسموح/);
  }, 10000);
});
