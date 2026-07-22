// Social link enrichment: scans a business's own official website first (no
// external search API needed for that path), then falls back to an official
// search API (Google Programmable Search Engine / Custom Search JSON API —
// https://developers.google.com/custom-search/v1/overview) for whichever
// platforms weren't found on the website. Never scrapes Google's HTML search
// results directly.
import { normalizeArabicText, normalizeEgyptianPhone, similarityScore } from './normalize';

export type SocialPlatform = 'facebook' | 'instagram' | 'tiktok';

export type SocialEvidence =
  | 'official_website'
  | 'name_match'
  | 'partial_name_match'
  | 'same_area'
  | 'username_match'
  | 'same_phone'
  | 'same_whatsapp'
  | 'reciprocal_website_link';

export type SocialLinkResult = {
  url: string;
  confidence: number;
  evidence: SocialEvidence[];
  source: 'official_website' | 'search';
};

export type SocialEnrichmentOutcome = {
  accepted: Partial<Record<SocialPlatform, SocialLinkResult>>;
  candidates: Partial<Record<SocialPlatform, SocialLinkResult>>;
  whatsapp: string | null;
  status: 'COMPLETED' | 'FAILED';
  error?: string;
};

const ACCEPT_THRESHOLD = 0.85;
const CANDIDATE_THRESHOLD = 0.6;
const REQUEST_TIMEOUT_MS = 8000;
const MAX_HTML_BYTES = 2 * 1024 * 1024;

const PLATFORM_HOSTS: Record<SocialPlatform, string[]> = {
  facebook: ['facebook.com', 'm.facebook.com', 'fb.com', 'fb.watch'],
  instagram: ['instagram.com', 'instagr.am'],
  tiktok: ['tiktok.com', 'vm.tiktok.com'],
};

const WHATSAPP_HOSTS = ['wa.me', 'api.whatsapp.com', 'chat.whatsapp.com'];

export function isSocialEnrichmentConfigured(): boolean {
  if (process.env.SOCIAL_ENRICHMENT_ENABLED !== 'true') return false;
  const provider = process.env.SEARCH_PROVIDER;
  if (provider === 'google_custom_search') {
    return Boolean(process.env.SEARCH_API_KEY?.trim() && process.env.SEARCH_ENGINE_ID?.trim());
  }
  return false;
}

/** Rejects anything but https/http links to the expected platform domain. */
export function isSafeExternalUrl(candidate: string, allowedHosts: string[]): boolean {
  try {
    const url = new URL(candidate);
    if (url.protocol !== 'https:' && url.protocol !== 'http:') return false;
    const host = url.hostname.toLowerCase();
    return allowedHosts.some((allowed) => host === allowed || host.endsWith(`.${allowed}`));
  } catch {
    return false;
  }
}

function usernameFromUrl(url: string): string {
  try {
    const path = new URL(url).pathname.replace(/\/+$/, '');
    return path.split('/').filter(Boolean).pop() ?? '';
  } catch {
    return '';
  }
}

function isFetchableHttpUrl(candidate: string): boolean {
  try {
    const url = new URL(candidate);
    return url.protocol === 'https:' || url.protocol === 'http:';
  } catch {
    return false;
  }
}

/** Pulls every href-like URL out of raw HTML — no DOM parser dependency needed for this. */
function extractHrefs(html: string, baseUrl: string): string[] {
  const hrefs = new Set<string>();
  const pattern = /href\s*=\s*["']([^"'#\s]+)["']/gi;
  let match: RegExpExecArray | null;
  while ((match = pattern.exec(html))) {
    try {
      hrefs.add(new URL(match[1], baseUrl).toString());
    } catch {
      // ignore malformed hrefs
    }
  }
  return [...hrefs];
}

async function fetchHtml(url: string): Promise<string | null> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);
  try {
    const response = await fetch(url, { signal: controller.signal, redirect: 'follow' });
    if (!response.ok) return null;
    const contentType = response.headers.get('content-type') ?? '';
    if (!contentType.includes('text/html') && !contentType.includes('text')) return null;
    const text = await response.text();
    return text.slice(0, MAX_HTML_BYTES);
  } catch {
    return null;
  } finally {
    clearTimeout(timer);
  }
}

/** Scans a business's own website (a page it publishes itself — not a third-party scrape). */
export async function extractSocialLinksFromWebsite(websiteUrl: string): Promise<{
  links: Partial<Record<SocialPlatform, string>>;
  whatsapp: string | null;
}> {
  const html = await fetchHtml(websiteUrl);
  if (!html) return { links: {}, whatsapp: null };
  return extractSocialLinksFromHtml(html, websiteUrl);
}

/** Pure function so it can be unit-tested without any network access. */
export function extractSocialLinksFromHtml(html: string, baseUrl: string): {
  links: Partial<Record<SocialPlatform, string>>;
  whatsapp: string | null;
} {
  const hrefs = extractHrefs(html, baseUrl);
  const links: Partial<Record<SocialPlatform, string>> = {};
  let whatsapp: string | null = null;

  for (const href of hrefs) {
    for (const platform of Object.keys(PLATFORM_HOSTS) as SocialPlatform[]) {
      if (!links[platform] && isSafeExternalUrl(href, PLATFORM_HOSTS[platform])) {
        links[platform] = href;
      }
    }
    if (!whatsapp && isSafeExternalUrl(href, WHATSAPP_HOSTS)) {
      const digits = href.match(/(?:wa\.me\/|phone=)(\d+)/i)?.[1];
      whatsapp = normalizeEgyptianPhone(digits ? `+${digits}` : null);
    }
  }

  return { links, whatsapp };
}

type SearchResultItem = { link: string; title?: string; snippet?: string };

/** Google Programmable Search Engine (Custom Search JSON API) — official, ToS-compliant. */
async function googleCustomSearch(q: string): Promise<SearchResultItem[]> {
  const apiKey = process.env.SEARCH_API_KEY;
  const engineId = process.env.SEARCH_ENGINE_ID;
  if (!apiKey || !engineId) return [];

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);
  try {
    const url = new URL('https://www.googleapis.com/customsearch/v1');
    url.searchParams.set('key', apiKey);
    url.searchParams.set('cx', engineId);
    url.searchParams.set('q', q);
    url.searchParams.set('num', '5');

    const response = await fetch(url, { signal: controller.signal });
    if (!response.ok) return [];
    const body = await response.json() as { items?: SearchResultItem[] };
    return body.items ?? [];
  } catch {
    return [];
  } finally {
    clearTimeout(timer);
  }
}

export function scoreCandidate(params: {
  source: 'official_website' | 'search';
  businessName: string;
  area?: string | null;
  phone?: string | null;
  candidateUrl: string;
  candidateText?: string;
}): { confidence: number; evidence: SocialEvidence[] } {
  // An official-website match starts meaningfully ahead of a search guess, but
  // still lands in the "needs review" band on its own — a footer/template link
  // isn't proof it's *this* business's own profile until something corroborates it.
  const evidence: SocialEvidence[] = [];
  let score = params.source === 'official_website' ? 0.65 : 0.15;
  if (params.source === 'official_website') evidence.push('official_website');

  const nameTokenScore = similarityScore(params.businessName, params.candidateText ?? '');
  if (nameTokenScore >= 0.5) {
    score += 0.3;
    evidence.push('name_match');
  } else if (nameTokenScore >= 0.25) {
    score += 0.15;
    evidence.push('partial_name_match');
  }

  if (params.area && params.candidateText && normalizeArabicText(params.candidateText).includes(normalizeArabicText(params.area))) {
    score += 0.2;
    evidence.push('same_area');
  }

  const usernameScore = similarityScore(params.businessName, usernameFromUrl(params.candidateUrl).replace(/[._-]/g, ' '));
  if (usernameScore >= 0.5) {
    score += 0.15;
    evidence.push('username_match');
  }

  if (params.phone && params.candidateText?.replace(/\D/g, '').includes(params.phone.replace(/\D/g, ''))) {
    score += 0.35;
    evidence.push('same_phone');
  }

  return { confidence: Math.min(1, Math.round(score * 100) / 100), evidence };
}

export async function enrichRecordSocialLinks(record: {
  name: string;
  area?: string | null;
  phone?: string | null;
  website?: string | null;
}): Promise<SocialEnrichmentOutcome> {
  try {
    const accepted: Partial<Record<SocialPlatform, SocialLinkResult>> = {};
    const candidates: Partial<Record<SocialPlatform, SocialLinkResult>> = {};
    let whatsapp: string | null = null;

    if (record.website && isFetchableHttpUrl(record.website)) {
      const found = await extractSocialLinksFromWebsite(record.website);
      whatsapp = found.whatsapp;
      for (const platform of Object.keys(found.links) as SocialPlatform[]) {
        const url = found.links[platform];
        if (!url) continue;
        const { confidence, evidence } = scoreCandidate({
          source: 'official_website',
          businessName: record.name,
          area: record.area,
          phone: record.phone,
          candidateUrl: url,
          candidateText: usernameFromUrl(url),
        });
        const result: SocialLinkResult = { url, confidence, evidence, source: 'official_website' };
        if (confidence >= ACCEPT_THRESHOLD) accepted[platform] = result;
        else if (confidence >= CANDIDATE_THRESHOLD) candidates[platform] = result;
      }
    }

    if (isSocialEnrichmentConfigured()) {
      const platformLabels: Record<SocialPlatform, string> = { facebook: 'Facebook', instagram: 'Instagram', tiktok: 'TikTok' };
      for (const platform of Object.keys(platformLabels) as SocialPlatform[]) {
        if (accepted[platform]) continue; // official website already gave us a trusted link
        const query = [record.name, record.area, platformLabels[platform]].filter(Boolean).join(' ');
        const items = await googleCustomSearch(query);
        let best: { confidence: number; evidence: SocialEvidence[]; url: string } | null = null;
        for (const item of items) {
          if (!isSafeExternalUrl(item.link, PLATFORM_HOSTS[platform])) continue;
          const { confidence, evidence } = scoreCandidate({
            source: 'search',
            businessName: record.name,
            area: record.area,
            phone: record.phone,
            candidateUrl: item.link,
            candidateText: `${item.title ?? ''} ${item.snippet ?? ''}`,
          });
          if (!best || confidence > best.confidence) best = { confidence, evidence, url: item.link };
        }
        if (best && best.confidence >= ACCEPT_THRESHOLD) {
          accepted[platform] = { url: best.url, confidence: best.confidence, evidence: best.evidence, source: 'search' };
        } else if (best && best.confidence >= CANDIDATE_THRESHOLD) {
          candidates[platform] = { url: best.url, confidence: best.confidence, evidence: best.evidence, source: 'search' };
        }
      }
    }

    return { accepted, candidates, whatsapp, status: 'COMPLETED' };
  } catch (error) {
    return {
      accepted: {},
      candidates: {},
      whatsapp: null,
      status: 'FAILED',
      error: error instanceof Error ? error.message.slice(0, 300) : 'فشل إثراء روابط التواصل',
    };
  }
}
