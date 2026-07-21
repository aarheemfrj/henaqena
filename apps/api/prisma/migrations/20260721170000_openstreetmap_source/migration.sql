-- OpenStreetMap as a free, no-key data collection source. Does not touch
-- any previous migration.

ALTER TABLE "CollectedBusiness"
  ADD COLUMN "osmId" TEXT;

-- Postgres treats multiple NULLs as distinct, so non-OSM records are unaffected.
CREATE UNIQUE INDEX "CollectedBusiness_osmId_key" ON "CollectedBusiness"("osmId");

-- Free and requires no API key/billing, so it is active by default (unlike
-- google-maps, whose activation is computed dynamically from env at request time).
INSERT INTO "DataSource" ("id", "name", "kind", "isActive")
VALUES ('osm', 'OpenStreetMap', 'MAP_FREE', TRUE)
ON CONFLICT ("name") DO NOTHING;
