postgis_extension_Use_Case_day9.sql

--telecom-focused

It uses geography (meters out of the box), so you don’t have to worry about projections right now.

⸻

-- 1) Create a telecom schema

CREATE SCHEMA IF NOT EXISTS telecom;
SET search_path TO telecom, public;


⸻

-- 2) Towers, subscribers, CDR events, outages, fiber

-- Cell towers (point + coverage radius in meters)

DROP TABLE IF EXISTS cell_towers CASCADE;

CREATE TABLE cell_towers (
  tower_id   serial PRIMARY KEY,
  name       text,
  location   geography(Point,4326) NOT NULL,   -- lon/lat as a 'Point'
  coverage_m integer NOT NULL DEFAULT 3000      -- simple circular coverage
);



-- Subscribers (home location)

DROP TABLE IF EXISTS subscribers CASCADE;


CREATE TABLE subscribers (
  msisdn     text PRIMARY KEY,
  home_loc   geography(Point,4326) NOT NULL
);



-- Call/Data events (anonymized CDR sample; attach point from lon/lat)

DROP TABLE IF EXISTS cdr_events CASCADE;

CREATE TABLE cdr_events (
  id         bigserial PRIMARY KEY,
  msisdn     text NOT NULL,
  event_ts   timestamptz NOT NULL,
  lon        double precision NOT NULL,
  lat        double precision NOT NULL,
  event_pt   geography(Point,4326) GENERATED ALWAYS AS (ST_SetSRID(ST_MakePoint(lon,lat),4326)::geography) STORED,
  cell_hint  text
);



-- Outage polygons (areas impacted)
DROP TABLE IF EXISTS outages CASCADE;
CREATE TABLE outages (
  outage_id  serial PRIMARY KEY,
  region     text,
  geom       geography(Polygon,4326) NOT NULL
);

-- Fiber/backhaul routes
DROP TABLE IF EXISTS fiber_routes CASCADE;
CREATE TABLE fiber_routes (
  route_id   serial PRIMARY KEY,
  name       text,
  path       geography(LineString,4326) NOT NULL
);


⸻

-- 3) Indexes (critical for performance)

CREATE INDEX ON cell_towers USING gist (location);
CREATE INDEX ON subscribers USING gist (home_loc);
CREATE INDEX ON cdr_events USING gist (event_pt);
CREATE INDEX ON outages USING gist (geom);
CREATE INDEX ON fiber_routes USING gist (path);


⸻

-- 4) Seed sample data (India cities; adjust as needed)

-- Towers: Mumbai, Delhi, Bengaluru, Chennai, Pune
INSERT INTO cell_towers (name, location, coverage_m) VALUES
  ('T_Mumbai_A',     ST_GeogFromText('SRID=4326;POINT(72.8777 19.0760)'), 3000),
  ('T_Delhi_A',      ST_GeogFromText('SRID=4326;POINT(77.2090 28.6139)'), 3500),
  ('T_Bengaluru_A',  ST_GeogFromText('SRID=4326;POINT(77.5946 12.9716)'), 2500),
  ('T_Chennai_A',    ST_GeogFromText('SRID=4326;POINT(80.2707 13.0827)'), 3000),
  ('T_Pune_A',       ST_GeogFromText('SRID=4326;POINT(73.8567 18.5204)'), 2500);

-- Subscribers near those cities
INSERT INTO subscribers (msisdn, home_loc) VALUES
  ('919812300001', ST_GeogFromText('SRID=4326;POINT(72.88 19.08)')),
  ('919812300002', ST_GeogFromText('SRID=4326;POINT(77.21 28.62)')),
  ('919812300003', ST_GeogFromText('SRID=4326;POINT(77.60 12.98)')),
  ('919812300004', ST_GeogFromText('SRID=4326;POINT(80.28 13.08)')),
  ('919812300005', ST_GeogFromText('SRID=4326;POINT(73.86 18.53)'));

-- A few CDR events (lon, lat are in degrees)
INSERT INTO cdr_events (msisdn, event_ts, lon, lat, cell_hint) VALUES
  ('919812300001', now() - interval '10 min', 72.879, 19.074, 'T_Mumbai_A'),
  ('919812300001', now() - interval '3 min',  72.882, 19.078, 'T_Mumbai_A'),
  ('919812300002', now() - interval '5 min',  77.210, 28.615, 'T_Delhi_A'),
  ('919812300003', now() - interval '12 min', 77.596, 12.972, 'T_Bengaluru_A'),
  ('919812300004', now() - interval '8 min',  80.273, 13.080, 'T_Chennai_A');

-- One simple outage polygon near Mumbai (tiny box for demo)
INSERT INTO outages (region, geom)
VALUES ('Mumbai_West',
  ST_GeogFromText('SRID=4326;POLYGON((72.87 19.07, 72.89 19.07, 72.89 19.09, 72.87 19.09, 72.87 19.07))')
);

-- Simple fiber route in Pune (two-point line)
INSERT INTO fiber_routes (name, path)
VALUES ('Pune_Backhaul',
  ST_GeogFromText('SRID=4326;LINESTRING(73.85 18.52, 73.87 18.53)')
);


⸻

-- 5) Core telecom queries you’ll actually use

-- A) Nearest towers for a subscriber (top 3)

SELECT t.tower_id, t.name,
       ST_Distance(s.home_loc, t.location) AS meters
FROM subscribers s
JOIN cell_towers t ON TRUE
WHERE s.msisdn = '919812300001'
ORDER BY s.home_loc <-> t.location   -- uses spatial index for KNN
LIMIT 3;


-- B) Which subscribers are inside a tower’s coverage?

SELECT s.msisdn, t.name AS tower, 
       ST_Distance(s.home_loc, t.location) AS meters
FROM subscribers s
JOIN cell_towers t
  ON ST_DWithin(s.home_loc, t.location, t.coverage_m);

-- C) Assign each subscriber to its closest tower

SELECT s.msisdn, t.name AS nearest_tower
FROM subscribers s
JOIN LATERAL (
  SELECT name
  FROM cell_towers
  ORDER BY s.home_loc <-> location
  LIMIT 1
) t ON true;

-- D) Overlapping coverage pairs (simplified circular buffers)

WITH cov AS (
  SELECT tower_id, name, ST_Buffer(location, coverage_m)::geography AS cov_geom
  FROM cell_towers
)
SELECT a.name AS t1, b.name AS t2
FROM cov a
JOIN cov b
  ON a.tower_id < b.tower_id
 AND ST_Intersects(a.cov_geom, b.cov_geom);

-- E) Outage impact: which subscribers lie in an outage polygon?

SELECT o.region, s.msisdn
FROM outages o
JOIN subscribers s
  ON ST_Contains(o.geom, s.home_loc)
ORDER BY o.region, s.msisdn;

-- F) Which towers are affected by an outage (coverage intersects outage)

WITH cov AS (
  SELECT t.*, ST_Buffer(t.location, t.coverage_m)::geography AS cov_geom
  FROM cell_towers t
)
SELECT DISTINCT o.region, t.name
FROM outages o
JOIN cov t ON ST_Intersects(o.geom, t.cov_geom)
ORDER BY o.region, t.name;

-- G) Nearest tower per CDR event (for quick attachment inference)

SELECT e.id, e.msisdn, e.event_ts, t.name AS nearest_tower,
       ST_Distance(e.event_pt, t.location) AS meters
FROM cdr_events e
JOIN LATERAL (
  SELECT name
  FROM cell_towers
  ORDER BY e.event_pt <-> location
  LIMIT 1
) t ON true
ORDER BY e.event_ts DESC
LIMIT 20;

-- H) Hotspots: count events within 1 km of each tower (recent 1 hour)

SELECT t.name, COUNT(*) AS events_last_hour
FROM cell_towers t
JOIN cdr_events e
  ON e.event_ts >= now() - interval '1 hour'
 AND ST_DWithin(e.event_pt, t.location, 1000)
GROUP BY t.name
ORDER BY events_last_hour DESC;

-- I) Fiber proximity: towers within 100 m of a fiber route

SELECT f.name AS route, t.name AS tower, ST_Distance(f.path, t.location) AS meters
FROM fiber_routes f
JOIN cell_towers t ON ST_DWithin(f.path, t.location, 100)
ORDER BY route, meters;
