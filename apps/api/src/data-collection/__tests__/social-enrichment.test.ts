/**
 * extractSocialLinksFromHtml/scoreCandidate/isSafeExternalUrl are pure and
 * tested directly with static fixtures — no network involved. The website-scan
 * path in enrichRecordSocialLinks is tested with a mocked fetch. The
 * search-API path (Google Custom Search) is NOT exercised live — no
 * SEARCH_API_KEY is available in this environment.
 */
import {
  enrichRecordSocialLinks,
  extractSocialLinksFromHtml,
  isSafeExternalUrl,
  scoreCandidate,
} from '../social-enrichment';

const ORIGINAL_ENV = { ...process.env };
const ORIGINAL_FETCH = global.fetch;

afterEach(() => {
  process.env = { ...ORIGINAL_ENV };
  global.fetch = ORIGINAL_FETCH;
  jest.restoreAllMocks();
});

describe('isSafeExternalUrl', () => {
  it('accepts an exact host match', () => {
    expect(isSafeExternalUrl('https://facebook.com/studio.qena', ['facebook.com'])).toBe(true);
  });

  it('accepts a subdomain of an allowed host', () => {
    expect(isSafeExternalUrl('https://m.facebook.com/studio.qena', ['facebook.com'])).toBe(true);
  });

  it('rejects a look-alike domain', () => {
    expect(isSafeExternalUrl('https://facebook.com.evil.example/x', ['facebook.com'])).toBe(false);
  });

  it('rejects non-http(s) protocols', () => {
    expect(isSafeExternalUrl('javascript:alert(1)', ['facebook.com'])).toBe(false);
  });

  it('rejects a disallowed host', () => {
    expect(isSafeExternalUrl('https://instagram.com/x', ['facebook.com'])).toBe(false);
  });
});

describe('extractSocialLinksFromHtml', () => {
  it('finds facebook/instagram/tiktok/whatsapp links from a business website', () => {
    const html = `
      <html><body>
        <a href="https://www.facebook.com/studio.qena.example">فيسبوك</a>
        <a href="https://instagram.com/studio_qena">إنستجرام</a>
        <a href="https://www.tiktok.com/@studio.qena">تيك توك</a>
        <a href="https://wa.me/201000000000">واتساب</a>
        <a href="https://unrelated-ads.example/track">إعلان</a>
      </body></html>
    `;
    const result = extractSocialLinksFromHtml(html, 'https://studio-qena.example');
    expect(result.links.facebook).toBe('https://www.facebook.com/studio.qena.example');
    expect(result.links.instagram).toBe('https://instagram.com/studio_qena');
    expect(result.links.tiktok).toBe('https://www.tiktok.com/@studio.qena');
    expect(result.whatsapp).toBe('01000000000');
  });

  it('resolves relative hrefs against the base URL and ignores non-platform links', () => {
    const html = '<a href="/contact">اتصل بنا</a>';
    const result = extractSocialLinksFromHtml(html, 'https://studio-qena.example');
    expect(result.links).toEqual({});
    expect(result.whatsapp).toBeNull();
  });

  it('returns nothing for a page with no matching links', () => {
    const result = extractSocialLinksFromHtml('<html><body>لا يوجد شيء هنا</body></html>', 'https://x.example');
    expect(result.links).toEqual({});
    expect(result.whatsapp).toBeNull();
  });
});

describe('scoreCandidate — confidence buckets', () => {
  it('scores high confidence for an official-website link with a strong name match', () => {
    const { confidence, evidence } = scoreCandidate({
      source: 'official_website',
      businessName: 'استوديو مثال للتصوير',
      area: 'مدينة قنا',
      candidateUrl: 'https://facebook.com/studio.mithal',
      candidateText: 'استوديو مثال للتصوير مدينة قنا',
    });
    expect(confidence).toBeGreaterThanOrEqual(0.85);
    expect(evidence).toContain('official_website');
    expect(evidence).toContain('name_match');
  });

  it('scores medium confidence for a search result whose name and area both match but has no other corroboration', () => {
    const { confidence, evidence } = scoreCandidate({
      source: 'search',
      businessName: 'استوديو مثال للتصوير',
      area: 'مدينة قنا',
      candidateUrl: 'https://facebook.com/some.studio',
      candidateText: 'استوديو مثال للتصوير في مدينة قنا',
    });
    expect(confidence).toBeGreaterThanOrEqual(0.6);
    expect(confidence).toBeLessThan(0.85);
    expect(evidence).toContain('name_match');
    expect(evidence).toContain('same_area');
  });

  it('scores low confidence for an unrelated search result', () => {
    const { confidence } = scoreCandidate({
      source: 'search',
      businessName: 'استوديو مثال للتصوير',
      candidateUrl: 'https://facebook.com/totally.unrelated.page',
      candidateText: 'صفحة عشوائية لا علاقة لها بالنشاط',
    });
    expect(confidence).toBeLessThan(0.6);
  });
});

describe('enrichRecordSocialLinks — auto-accept thresholds', () => {
  it('does not blindly accept a low-confidence link — no facebook set', async () => {
    global.fetch = jest.fn(async () => ({
      ok: true,
      status: 200,
      headers: new Headers({ 'content-type': 'text/html' }),
      text: async () => '<a href="https://facebook.com/random-unrelated-page">صفحة</a>',
    } as unknown as Response)) as unknown as typeof fetch;

    const outcome = await enrichRecordSocialLinks({
      name: 'استوديو مثال للتصوير',
      area: 'مدينة قنا',
      phone: '01000000000',
      website: 'https://studio-qena.example',
    });

    expect(outcome.status).toBe('COMPLETED');
    expect(outcome.accepted.facebook).toBeUndefined();
  });

  it('auto-accepts an official-website match once the URL slug itself corroborates the business name', async () => {
    // Real-world case: an Egyptian business with a Latin-transliterated Facebook slug.
    global.fetch = jest.fn(async () => ({
      ok: true,
      status: 200,
      headers: new Headers({ 'content-type': 'text/html' }),
      text: async () => '<a href="https://facebook.com/studio.mithal.photography">Follow us</a>',
    } as unknown as Response)) as unknown as typeof fetch;

    const outcome = await enrichRecordSocialLinks({
      name: 'Studio Mithal Photography',
      area: 'Qena',
      phone: '01000000000',
      website: 'https://studio-qena.example',
    });

    expect(outcome.status).toBe('COMPLETED');
    expect(outcome.accepted.facebook?.url).toBe('https://facebook.com/studio.mithal.photography');
    expect(outcome.accepted.facebook?.confidence).toBeGreaterThanOrEqual(0.85);
    expect(outcome.accepted.facebook?.evidence).toContain('official_website');
  });

  it('leaves an official-website match with no corroborating signal as a candidate, not auto-accepted', async () => {
    global.fetch = jest.fn(async () => ({
      ok: true,
      status: 200,
      headers: new Headers({ 'content-type': 'text/html' }),
      text: async () => '<a href="https://facebook.com/totally-unrelated-slug-999">Follow us</a>',
    } as unknown as Response)) as unknown as typeof fetch;

    const outcome = await enrichRecordSocialLinks({
      name: 'استوديو مثال للتصوير',
      area: 'مدينة قنا',
      phone: '01000000000',
      website: 'https://studio-qena.example',
    });

    expect(outcome.status).toBe('COMPLETED');
    expect(outcome.accepted.facebook).toBeUndefined();
    expect(outcome.candidates.facebook?.url).toBe('https://facebook.com/totally-unrelated-slug-999');
    expect(outcome.candidates.facebook?.confidence).toBeGreaterThanOrEqual(0.6);
    expect(outcome.candidates.facebook?.confidence).toBeLessThan(0.85);
  });

  it('does not call the search API when SOCIAL_ENRICHMENT_ENABLED is not set', async () => {
    delete process.env.SOCIAL_ENRICHMENT_ENABLED;
    const fetchMock = jest.fn(async () => ({ ok: true, status: 200, headers: new Headers(), text: async () => '', json: async () => ({}) } as unknown as Response));
    global.fetch = fetchMock as unknown as typeof fetch;

    await enrichRecordSocialLinks({ name: 'نشاط بدون موقع', area: 'قوص', phone: null, website: null });
    expect(fetchMock).not.toHaveBeenCalled();
  });
});
