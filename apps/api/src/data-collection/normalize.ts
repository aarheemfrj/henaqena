import { createHash } from 'node:crypto';

const arabicDiacritics = /[\u0617-\u061A\u064B-\u0652]/g;
const nonWord = /[^\p{L}\p{N}]+/gu;

export const normalizeArabicText = (value?: string | null): string =>
  (value ?? '')
    .trim()
    .toLowerCase()
    .replace(arabicDiacritics, '')
    .replace(/[أإآ]/g, 'ا')
    .replace(/ى/g, 'ي')
    .replace(/ة/g, 'ه')
    .replace(/ؤ/g, 'و')
    .replace(/ئ/g, 'ي')
    .replace(nonWord, ' ')
    .replace(/\s+/g, ' ')
    .trim();

export const normalizeEgyptianPhone = (value?: string | null): string | null => {
  if (!value) return null;

  let digits = value.replace(/\D/g, '');
  if (digits.startsWith('0020')) digits = digits.slice(4);
  if (digits.startsWith('20') && digits.length >= 12) digits = digits.slice(2);
  if (digits.length === 10 && digits.startsWith('1')) digits = `0${digits}`;

  return /^01[0125]\d{8}$/.test(digits) ? digits : null;
};

export const normalizeUrl = (value?: string | null): string | null => {
  if (!value) return null;
  const candidate = value.trim();
  if (!candidate) return null;

  try {
    const url = new URL(/^https?:\/\//i.test(candidate) ? candidate : `https://${candidate}`);
    url.hash = '';
    for (const key of ['utm_source', 'utm_medium', 'utm_campaign', 'utm_term', 'utm_content']) {
      url.searchParams.delete(key);
    }
    return url.toString().replace(/\/$/, '');
  } catch {
    return null;
  }
};

export const fingerprintBusiness = (input: {
  name: string;
  phone?: string | null;
  area?: string | null;
  address?: string | null;
  latitude?: number | null;
  longitude?: number | null;
}): string => {
  const normalizedName = normalizeArabicText(input.name);
  const normalizedPhone = normalizeEgyptianPhone(input.phone);

  const coordinates =
    typeof input.latitude === 'number' && typeof input.longitude === 'number'
      ? `${input.latitude.toFixed(4)}:${input.longitude.toFixed(4)}`
      : '';

  const identity = [
    normalizedName,
    normalizedPhone ?? '',
    normalizeArabicText(input.area),
    normalizeArabicText(input.address),
    coordinates,
  ].join('|');

  return createHash('sha256').update(identity).digest('hex');
};

export const calculateQualityScore = (input: Record<string, unknown>): number => {
  const weights: Record<string, number> = {
    phone: 20,
    whatsapp: 10,
    address: 10,
    latitude: 10,
    longitude: 10,
    category: 10,
    website: 5,
    facebook: 5,
    instagram: 5,
    tiktok: 3,
    googleMapsUrl: 5,
    rating: 4,
    reviewCount: 3,
  };

  return Math.min(
    100,
    Object.entries(weights).reduce((score, [field, weight]) => {
      const value = input[field];
      return value !== undefined && value !== null && value !== '' ? score + weight : score;
    }, 0),
  );
};

export const similarityScore = (left: string, right: string): number => {
  const a = new Set(normalizeArabicText(left).split(' ').filter(Boolean));
  const b = new Set(normalizeArabicText(right).split(' ').filter(Boolean));
  if (!a.size || !b.size) return 0;

  const intersection = [...a].filter((token) => b.has(token)).length;
  const union = new Set([...a, ...b]).size;
  return intersection / union;
};
