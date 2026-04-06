# Upgrading PostgreSQL to PostGIS

PostGIS is a PostgreSQL extension — enabling it on an existing database requires no data migration or schema changes. It adds geometry/geography types, spatial functions, and a `spatial_ref_sys` reference table alongside your existing data.

---

## Prerequisites

PostGIS binaries must be installed on the PostgreSQL server before the extension can be enabled.

### Check if PostGIS is already available

```sql
SELECT * FROM pg_available_extensions WHERE name = 'postgis';
```

If a row is returned, skip to [Enabling the Extension](#enabling-the-extension). If not, install the binaries first.

### Install PostGIS binaries (Debian/Ubuntu)

```bash
sudo apt-get update
sudo apt-get install -y postgresql-16-postgis-3   # adjust version to match your postgres
```

For other versions, replace `16` with your Postgres major version (e.g., `15`, `14`).

### Install PostGIS binaries (Alpine — official `postgres` Docker image)

```bash
apk update
apk add --no-cache postgis
```

Alpine packages PostGIS under a single `postgis` package regardless of Postgres version. To see what version will be installed:

```bash
apk search postgis          # lists available packages, e.g. postgis-3.5.3-r0
```

To pin to a specific version, use `=` with just the version number (not the `-r0` release suffix):

```bash
apk add --no-cache postgis=3.5.3
```

---

## Enabling the Extension

Connect to the target database as a superuser and run:

```sql
CREATE EXTENSION IF NOT EXISTS postgis;
```

Optionally add topology support:

```sql
CREATE EXTENSION IF NOT EXISTS postgis_topology;
```

Verify:

```sql
SELECT PostGIS_Full_Version();
```

`IF NOT EXISTS` makes this idempotent — safe to re-run.

---

## Adding Spatial Columns to Existing Tables

Once the extension is enabled, alter existing tables to add geometry support:

```sql
-- Add a geography column (WGS84 / EPSG:4326 — standard GPS coordinates)
ALTER TABLE locations
    ADD COLUMN geom GEOGRAPHY(Point, 4326);

-- Populate from existing lat/lng columns
UPDATE locations
    SET geom = ST_MakePoint(lng, lat)::GEOGRAPHY;

-- Add a spatial index
CREATE INDEX idx_locations_geom ON locations USING GIST (geom);
```

Use `GEOGRAPHY` (not `GEOMETRY`) for GPS lat/lng values — it handles spherical earth math correctly for distance queries.

---

## Flyway / Liquibase Migration

If using Flyway, add extension creation as an early migration so it runs automatically on deploy:

```sql
-- V1__enable_postgis.sql
CREATE EXTENSION IF NOT EXISTS postgis;
```

---

## Verify Spatial Functions Work

```sql
SELECT ST_Distance(
    ST_MakePoint(-73.9857, 40.7484)::GEOGRAPHY,
    ST_MakePoint(-87.6298, 41.8781)::GEOGRAPHY
) AS distance_meters;
-- Expected: ~1,144,000 meters (NYC to Chicago)
```
