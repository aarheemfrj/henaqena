export type CollectedRecordStatus = 'NEW' | 'NEEDS_REVIEW' | 'APPROVED' | 'REJECTED' | 'MERGED';

export type CollectedBusiness = {
  id: string;
  jobId: string | null;
  sourceId: string | null;
  externalId: string | null;
  name: string;
  normalizedName: string;
  category: string | null;
  subcategory: string | null;
  city: string;
  area: string | null;
  village: string | null;
  address: string | null;
  latitude: number | null;
  longitude: number | null;
  phone: string | null;
  normalizedPhone: string | null;
  whatsapp: string | null;
  email: string | null;
  website: string | null;
  facebook: string | null;
  instagram: string | null;
  tiktok: string | null;
  googleMapsUrl: string | null;
  rating: number | null;
  reviewCount: number | null;
  openingHours: unknown;
  rawData: unknown;
  fingerprint: string;
  qualityScore: number;
  status: CollectedRecordStatus;
  reviewNote: string | null;
  reviewedAt: string | null;
  reviewedBy: string | null;
  providerId: string | null;
  createdAt: string;
  updatedAt: string;
};

export type DuplicateCandidate = {
  id: string;
  leftId: string;
  rightId: string;
  score: number;
  reason: string;
  resolved: boolean;
  resolution: string | null;
  createdAt: string;
  resolvedAt: string | null;
  left: CollectedBusiness;
  right: CollectedBusiness;
};

export type CollectionJob = {
  id: string;
  sourceId: string | null;
  category: string | null;
  area: string | null;
  query: string | null;
  status: 'PENDING' | 'RUNNING' | 'COMPLETED' | 'FAILED' | 'CANCELLED';
  startedAt: string | null;
  finishedAt: string | null;
  foundCount: number;
  savedCount: number;
  duplicateCount: number;
  failedCount: number;
  error: string | null;
  createdAt: string;
  updatedAt: string;
};

export type DataCollectionOverview = {
  statuses: Partial<Record<CollectedRecordStatus, number>>;
  unresolvedDuplicates: number;
  latestJobs: CollectionJob[];
};
