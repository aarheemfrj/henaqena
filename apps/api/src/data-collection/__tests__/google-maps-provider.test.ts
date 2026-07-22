/**
 * These tests mock global fetch and never call the real Google Places API —
 * no GOOGLE_MAPS_API_KEY is available in this environment, so the live
 * network path has NOT been exercised. See google-maps-job-runner tests for
 * the same disclosure on the end-to-end job flow.
 */
import {
  buildGoogleMapsUrl,
  composeSearchQuery,
  GoogleMapsQuotaError,
  isGoogleMapsConfigured,
  searchGooglePlaces,
  type GooglePlaceResult,
} from '../google-maps-provider';

const ORIGINAL_ENV = { ...process.env };
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
      text: async () => JSON.stringify(next.body),
    } as Response;
  }) as unknown as typeof fetch;
}

describe('composeSearchQuery', () => {
  it('joins category + area + query + قنا', () => {
    expect(composeSearchQuery({ category: 'استوديوهات تصوير', area: 'مدينة قنا', query: null }))
      .toBe('استوديوهات تصوير مدينة قنا قنا');
  });

  it('includes an optional query term when present', () => {
    expect(composeSearchQuery({ category: 'مطاعم', area: 'نجع حمادي', query: 'مشويات' }))
      .toBe('مطاعم نجع حمادي مشويات قنا');
  });

  it('drops empty/whitespace-only parts', () => {
    expect(composeSearchQuery({ category: 'مطاعم', area: '  ', query: '  ' })).toBe('مطاعم قنا');
  });
});

describe('buildGoogleMapsUrl', () => {
  it('prefers the official googleMapsUri when present', () => {
    const place: GooglePlaceResult = { id: 'abc123', googleMapsUri: 'https://maps.google.com/?cid=1' };
    expect(buildGoogleMapsUrl(place)).toBe('https://maps.google.com/?cid=1');
  });

  it('falls back to a stable place_id URL when googleMapsUri is missing', () => {
    const place: GooglePlaceResult = { id: 'abc 123' };
    expect(buildGoogleMapsUrl(place)).toBe('https://www.google.com/maps/place/?q=place_id:abc%20123');
  });
});

describe('isGoogleMapsConfigured', () => {
  afterEach(() => { process.env = { ...ORIGINAL_ENV }; });

  it('is false when the flag is off even with a key present', () => {
    process.env.GOOGLE_MAPS_PROVIDER_ENABLED = 'false';
    process.env.GOOGLE_MAPS_API_KEY = 'fake-key';
    expect(isGoogleMapsConfigured()).toBe(false);
  });

  it('is false when enabled but no key is set', () => {
    process.env.GOOGLE_MAPS_PROVIDER_ENABLED = 'true';
    delete process.env.GOOGLE_MAPS_API_KEY;
    expect(isGoogleMapsConfigured()).toBe(false);
  });

  it('is true only when both are set', () => {
    process.env.GOOGLE_MAPS_PROVIDER_ENABLED = 'true';
    process.env.GOOGLE_MAPS_API_KEY = 'fake-key';
    expect(isGoogleMapsConfigured()).toBe(true);
  });
});

describe('searchGooglePlaces (mocked fetch)', () => {
  beforeEach(() => {
    process.env.GOOGLE_MAPS_PROVIDER_ENABLED = 'true';
    process.env.GOOGLE_MAPS_API_KEY = 'fake-key';
  });
  afterEach(() => {
    process.env = { ...ORIGINAL_ENV };
    global.fetch = ORIGINAL_FETCH;
    jest.restoreAllMocks();
  });

  it('throws when the provider is not configured', async () => {
    process.env.GOOGLE_MAPS_PROVIDER_ENABLED = 'false';
    await expect(searchGooglePlaces({ textQuery: 'x', limit: 10 })).rejects.toThrow();
  });

  it('paginates until the requested limit is reached', async () => {
    mockFetchSequence([
      { status: 200, body: { places: Array.from({ length: 20 }, (_, i) => ({ id: `p${i}` })), nextPageToken: 'tok1' } },
      { status: 200, body: { places: Array.from({ length: 5 }, (_, i) => ({ id: `q${i}` })) } },
    ]);
    const results = await searchGooglePlaces({ textQuery: 'مطاعم قنا', limit: 25 });
    expect(results).toHaveLength(25);
    expect(global.fetch).toHaveBeenCalledTimes(2);
  }, 15000);

  it('never returns more than the documented 60-result cap even if limit is higher', async () => {
    mockFetchSequence([
      { status: 200, body: { places: Array.from({ length: 20 }, (_, i) => ({ id: `a${i}` })), nextPageToken: 't1' } },
      { status: 200, body: { places: Array.from({ length: 20 }, (_, i) => ({ id: `b${i}` })), nextPageToken: 't2' } },
      { status: 200, body: { places: Array.from({ length: 20 }, (_, i) => ({ id: `c${i}` })), nextPageToken: 't3' } },
    ]);
    const results = await searchGooglePlaces({ textQuery: 'مطاعم قنا', limit: 500 });
    expect(results).toHaveLength(60);
  }, 15000);

  it('throws GoogleMapsQuotaError on HTTP 429 without retrying', async () => {
    mockFetchSequence([{ status: 429, body: { error: 'quota' } }]);
    await expect(searchGooglePlaces({ textQuery: 'x', limit: 10 })).rejects.toBeInstanceOf(GoogleMapsQuotaError);
    expect(global.fetch).toHaveBeenCalledTimes(1);
  });

  it('retries transient failures with backoff and eventually succeeds', async () => {
    mockFetchSequence([
      { status: 500, body: { error: 'server error' } },
      { status: 500, body: { error: 'server error' } },
      { status: 200, body: { places: [{ id: 'ok1' }] } },
    ]);
    const results = await searchGooglePlaces({ textQuery: 'x', limit: 10 });
    expect(results).toHaveLength(1);
    expect(global.fetch).toHaveBeenCalledTimes(3);
  }, 15000);

  it('gives up after exhausting retries on persistent failure', async () => {
    mockFetchSequence([
      { status: 500, body: {} },
      { status: 500, body: {} },
      { status: 500, body: {} },
    ]);
    await expect(searchGooglePlaces({ textQuery: 'x', limit: 10 })).rejects.toThrow();
    expect(global.fetch).toHaveBeenCalledTimes(3);
  }, 15000);
});
