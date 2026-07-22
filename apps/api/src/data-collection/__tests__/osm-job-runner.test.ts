/**
 * The osm-provider module is mocked here — this suite tests the job runner's
 * own orchestration (dedup decision, progress bookkeeping, clean failure on
 * an unmapped category or failed geocode), not live network calls.
 */
import { runOsmJob } from '../osm-job-runner';
import type { CollectionJobRow } from '../collection-job-shared';
import { OsmProviderError } from '../osm-provider';
import type { OsmElement } from '../osm-provider';

jest.mock('../osm-provider', () => {
  const actual = jest.requireActual('../osm-provider');
  return { ...actual, geocodeArea: jest.fn(), searchOsmPlaces: jest.fn() };
});
jest.mock('../social-enrichment', () => ({
  isSocialEnrichmentConfigured: () => false,
  enrichRecordSocialLinks: jest.fn(async () => ({ accepted: {}, candidates: {}, whatsapp: null, status: 'COMPLETED' })),
}));

// eslint-disable-next-line @typescript-eslint/no-var-requires
const { geocodeArea, searchOsmPlaces } = jest.requireMock('../osm-provider') as {
  geocodeArea: jest.Mock; searchOsmPlaces: jest.Mock;
};

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
  id: 'job-osm-1', sourceId: 'osm', category: 'مطاعم', area: 'مدينة قنا', query: null,
  metadata: { limit: 10 },
};

afterEach(() => jest.clearAllMocks());

describe('runOsmJob', () => {
  it('fails cleanly with a clear message when the category has no OSM tag mapping', async () => {
    const { prisma, calls } = makeFakePrisma();
    await runOsmJob(prisma as never, { ...baseJob, category: 'فئة غير مدعومة' });

    const failedCall = calls.find((c) => c.sql.includes(`"status" = 'FAILED'`));
    expect(failedCall).toBeDefined();
    expect(String(failedCall?.params[1])).toMatch(/غير مدعومة/);
    expect(geocodeArea).not.toHaveBeenCalled();
  });

  it('fails cleanly when the area cannot be geocoded', async () => {
    const { prisma, calls } = makeFakePrisma();
    geocodeArea.mockResolvedValue(null);

    await runOsmJob(prisma as never, baseJob);

    const failedCall = calls.find((c) => c.sql.includes(`"status" = 'FAILED'`));
    expect(failedCall).toBeDefined();
    expect(String(failedCall?.params[1])).toMatch(/تعذر تحديد موقع/);
    expect(searchOsmPlaces).not.toHaveBeenCalled();
  });

  it('inserts a new record when no dedup match is found', async () => {
    const { prisma, calls, setDedupResults } = makeFakePrisma();
    geocodeArea.mockResolvedValue({ lat: 26.16, lon: 32.72, displayName: 'قنا' });
    const element: OsmElement = { type: 'node', id: 1, lat: 26.16, lon: 32.72, tags: { name: 'مطعم تجريبي' } };
    searchOsmPlaces.mockResolvedValue([element]);
    setDedupResults([[]]);

    await runOsmJob(prisma as never, baseJob);

    const insertCall = calls.find((c) => c.sql.includes('INSERT INTO "CollectedBusiness"') && c.sql.includes("'osm'"));
    expect(insertCall).toBeDefined();
    const completedCall = calls.find((c) => c.sql.includes(`"status" = 'COMPLETED'`));
    expect(completedCall).toBeDefined();
  });

  it('updates the existing record instead of inserting when a dedup match exists', async () => {
    const { prisma, calls, setDedupResults } = makeFakePrisma();
    geocodeArea.mockResolvedValue({ lat: 26.16, lon: 32.72, displayName: 'قنا' });
    const element: OsmElement = { type: 'way', id: 2, center: { lat: 26.16, lon: 32.72 }, tags: { name: 'صيدلية موجودة' } };
    searchOsmPlaces.mockResolvedValue([element]);
    setDedupResults([[{ id: 'existing-osm-1' }]]);

    await runOsmJob(prisma as never, baseJob);

    const insertCall = calls.find((c) => c.sql.includes('INSERT INTO "CollectedBusiness"'));
    const updateCall = calls.find((c) => c.sql.includes('UPDATE "CollectedBusiness" SET') && c.sql.includes('"osmId" = COALESCE'));
    expect(insertCall).toBeUndefined();
    expect(updateCall).toBeDefined();
    expect(updateCall?.params[0]).toBe('existing-osm-1');
  });

  it('propagates a provider error (e.g. Overpass rate limit) as a FAILED job with the message intact', async () => {
    const { prisma, calls } = makeFakePrisma();
    geocodeArea.mockResolvedValue({ lat: 26.16, lon: 32.72, displayName: 'قنا' });
    searchOsmPlaces.mockRejectedValue(new OsmProviderError('تم تجاوز الحد المسموح لطلبات Overpass API'));

    await runOsmJob(prisma as never, baseJob);

    const failedCall = calls.find((c) => c.sql.includes(`"status" = 'FAILED'`));
    expect(String(failedCall?.params[1])).toMatch(/تجاوز الحد المسموح/);
  });
});
