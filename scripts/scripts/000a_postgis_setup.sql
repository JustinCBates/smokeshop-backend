-- ============================================================================
-- POSTGIS SETUP - Run this FIRST in Supabase SQL Editor
-- ============================================================================
-- This must complete successfully before running the main migration
-- ============================================================================

-- Enable PostGIS extension
CREATE EXTENSION IF NOT EXISTS postgis;

-- Enable UUID extension (needed for profiles table)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Verify PostGIS is working
SELECT PostGIS_version();

-- Verify spatial_ref_sys table exists
SELECT count(*) FROM spatial_ref_sys WHERE srid = 4326;
