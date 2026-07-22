/**
 * The Google Places provider and social-enrichment modules are mocked here —
 * this suite tests the job runner's own orchestration (dedup decision,
 * progress bookkeeping, clean quota-exhaustion handling), not live network
 * calls. No real Google API key is available in this environment.
 */
import { runGoogleMapsJob, type CollectionJobRow } from '../google-maps-job-runner';
import { GoogleMapsQuotaError } from '../google-maps-provider';
import type { GooglePlaceResult } from '../google-maps-provider';

jest.mock('../google-maps-provider', () => {
  const actual = jest.requireActual('../google-maps-provider');
  return { ...actual, iterateGooglePlaces: jest.fn() };
});
jest.mock('../social-enrichment', () => ({
  isSocialEnrichmentConfigured: () => false,
  enrichRecordSocialLinks: jest.fn(async () => ({ accepted: {}, candidates: {}, whatsapp: null, status: 'COMPLETED' })),
}));

// eslint-disable-next-line @typescript-eslint/no-var-requires
const { iterateGooglePlaces } = jest.requireMock('../google-maps-provider') as { iterateGooglePlaces: jest.Mock };

function makeFakePrisma() {
  const calls: Array<{ sql: string; params: unknown[] }> = [];
  const dedupResults: unknown[][] = [];
  let dedupCallIndex = 0;

  const prisma = {
    $queryRawUnsafe: jest.fn(async (sql: string, ...params: unknown[]) => {
      calls.push({ sql, params });
      if (sql.includes('SELECT "id" FROM "CollectedBusiness"')) {
        const result = dedupResults[dedupCallIndex] ?? [];
        dedupCallIndex += 1;
        return result;
      }
      if (sql.includes('SELECT "id", "name", "area", "phone", "website" FROM "CollectedBusiness"')) {
        return [{ id: 'generated-id', name: 'x', area: null, phone: null, website: null }];
      }
      return [];
    }),
    $executeRawUnsafe: jest.fn(async (sql: string, ...params: unknown[]) => {
      calls.push({ sql, params });
      return 1;
    }),
  };

  return { prisma, calls, setDedupResults: (results: unknown[][]) => { dedupResults.length = 0; dedupResults.push(...results); } };
}

const baseJob: CollectionJobRow = {
  id: 'job-1', sourceId: 'google-maps', category: 'مطاعم', area: 'مدينة قنا', query: null,
  metadata: { limit: 10 },
};

async function drainAsyncGenerator<T>(items: T[][]) {
  return (async function* () { for (const page of items) yield page; })();
}

afterEach(() => jest.clearAllMocks());

describe('runGoogleMapsJob', () => {
  it('inserts a new record when no dedup match is found', async () => {
    const { prisma, calls, setDedupResults } = makeFakePrisma();
    setDedupResults([[]]); // no existing match -> INSERT path
    const place: GooglePlaceResult = { id: 'place-1', displayName: { text: 'مطعم تجريبي' } };
    iterateGooglePlaces.mockReturnValue(await drainAsyncGenerator([[place]]));

    await runGoogleMapsJob(prisma as never, baseJob);

    const insertCall = calls.find((c) => c.sql.includes('INSERT INTO "CollectedBusiness"'));
    expect(insertCall).toBeDefined();
    const completedCall = calls.find((c) => c.sql.includes(`"status" = 'COMPLETED'`));
    expect(completedCall).toBeDefined();
  });

  it('updates the existing record instead of inserting when a placeId/phone/name+area match exists', async () => {
    const { prisma, calls, setDedupResults } = makeFakePrisma();
    setDedupResults([[{ id: 'existing-1' }]]); // dedup match found -> UPDATE path
    const place: GooglePlaceResult = { id: 'place-2', displayName: { text: 'صيدلية موجودة مسبقًا' } };
    iterateGooglePlaces.mockReturnValue(await drainAsyncGenerator([[place]]));

    await runGoogleMapsJob(prisma as never, baseJob);

    const insertCall = calls.find((c) => c.sql.includes('INSERT INTO "CollectedBusiness"'));
    const updateCall = calls.find((c) => c.sql.includes('UPDATE "CollectedBusiness" SET') && c.sql.includes('"googlePlaceId" = COALESCE'));
    expect(insertCall).toBeUndefined();
    expect(updateCall).toBeDefined();
    expect(updateCall?.params[0]).toBe('existing-1');
  });

  it('stops cleanly on quota exhaustion, marks the job FAILED, and keeps progress already saved', async () => {
    const { prisma, calls, setDedupResults } = makeFakePrisma();
    setDedupResults([[]]); // first page's single place is new
    const firstPlace: GooglePlaceResult = { id: 'place-3', displayName: { text: 'محل أول' } };

    async function* pages() {
      yield [firstPlace];
      throw new GoogleMapsQuotaError('quota exceeded');
    }
    iterateGooglePlaces.mockReturnValue(pages());

    await runGoogleMapsJob(prisma as never, baseJob);

    const progressCalls = calls.filter((c) => c.sql.includes('"savedCount" = $3'));
    expect(progressCalls.length).toBeGreaterThan(0); // first page's progress was saved before the failure
    const failedCall = calls.find((c) => c.sql.includes(`"status" = 'FAILED'`));
    expect(failedCall).toBeDefined();
    expect(String(failedCall?.params[1])).toMatch(/quota/i);
    const completedCall = calls.find((c) => c.sql.includes(`"status" = 'COMPLETED'`));
    expect(completedCall).toBeUndefined();
  });

  it('respects the limit stored in job metadata when composing the search request', async () => {
    const { prisma, setDedupResults } = makeFakePrisma();
    setDedupResults([[]]);
    iterateGooglePlaces.mockReturnValue(await drainAsyncGenerator([[]]));

    await runGoogleMapsJob(prisma as never, { ...baseJob, metadata: { limit: 7 } });

    expect(iterateGooglePlaces).toHaveBeenCalledWith(expect.objectContaining({ limit: 7 }));
  });
});
