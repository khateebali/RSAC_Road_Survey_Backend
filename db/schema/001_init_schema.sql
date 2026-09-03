-- ============================================================================
-- GNN Road Survey — initial schema
-- Database: gnn_road_survey (new, on db-primary — 27.100.38.132)
-- Source of every field decision: docs/gnn-survey/ (split from the approved
-- architecture plan) — Section 2 in particular. Do not run this against any
-- existing database (LKO_NN, nv_allnndb) — this creates a brand-new database.
--
-- Run as: createdb gnn_road_survey  (then) psql -d gnn_road_survey -f 001_init_schema.sql
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgcrypto;  -- gen_random_uuid(); no-op if already core

-- ----------------------------------------------------------------------------
-- Shared enums (kept as VARCHAR + CHECK rather than native ENUM types, so
-- adding a new dropdown value later is an ALTER ... DROP/ADD CONSTRAINT, not
-- a schema-breaking ALTER TYPE ... ADD VALUE inside a transaction).
-- ----------------------------------------------------------------------------

-- data_source / qa_status recur on every survey-detail table.
-- data_source: 'primary_db_import' | 'field_created' | 'field_corrected'
-- qa_status:   'pending_field_verification' | 'field_verified' | 'flagged'

-- ============================================================================
-- 2.1  road_inventory  (master table, seeded from ghaziabad_road_net)
-- ============================================================================
CREATE TABLE road_inventory (
    road_id                     VARCHAR(64)  PRIMARY KEY,   -- reused verbatim from ghaziabad_road_net
    nagar_nigam_id              VARCHAR(32)  NOT NULL DEFAULT 'GNN',

    road_name                   VARCHAR(255),
    local_name                  VARCHAR(255),
    ward_no                     VARCHAR(32),
    ward_name                   VARCHAR(255),
    zone_no                     VARCHAR(32),
    zone_name                   VARCHAR(255),
    locality                    VARCHAR(255),

    category                    VARCHAR(64),   -- Expressway/Arterial/Sub-Arterial/Collector Street/
                                                  -- Local Street/Service Road/Other
    ownership                   VARCHAR(64),   -- carried from ghaziabad_road_net.ownership
    own_class                   VARCHAR(128),  -- carried from ghaziabad_road_net.own_class
    maintaining_agency          VARCHAR(128),  -- derived from ownership; kept separate in case
                                                  -- they diverge during field verification
    construction_scheme         VARCHAR(255),  -- old Flutter form's 'cus' field, added after
                                                  -- the Section 1.5 field-reconciliation check

    year_of_construction        NUMERIC(6,0),
    nearby_landmark              VARCHAR(255),

    start_point                  geometry(Point, 4326),
    end_point                    geometry(Point, 4326),
    geom                         geometry(MultiLineString, 4326) NOT NULL,

    length_m                     NUMERIC(10,2),
    length_km                    NUMERIC(10,3),

    -- Section 3: network topology placeholders — unpopulated at launch, present so a
    -- future pgRouting graph doesn't need a migration against live survey data.
    from_node_id                  VARCHAR(64),
    to_node_id                    VARCHAR(64),

    data_source                   VARCHAR(32)  NOT NULL DEFAULT 'primary_db_import'
                                    CHECK (data_source IN ('primary_db_import','field_created','field_corrected')),
    qa_status                     VARCHAR(32)  NOT NULL DEFAULT 'pending_field_verification'
                                    CHECK (qa_status IN ('pending_field_verification','field_verified','flagged')),
    survey_date                   DATE,
    surveyor_id                   UUID,        -- FK to users(user_id) added after users table exists

    created_at                    TIMESTAMP NOT NULL DEFAULT now(),
    updated_at                    TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX idx_road_inventory_geom ON road_inventory USING GIST (geom);
CREATE INDEX idx_road_inventory_ward ON road_inventory (ward_no);
CREATE INDEX idx_road_inventory_zone ON road_inventory (zone_no);
CREATE INDEX idx_road_inventory_qa_status ON road_inventory (qa_status);

-- ============================================================================
-- 2.2  road_geometry  (road_id FK, 1:1)
-- ============================================================================
CREATE TABLE road_geometry (
    road_geometry_id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    road_id                      VARCHAR(64) NOT NULL UNIQUE REFERENCES road_inventory(road_id),
    nagar_nigam_id               VARCHAR(32) NOT NULL DEFAULT 'GNN',

    row_width_m                  NUMERIC(8,2),   -- old form's 'row_meter' — field-measured RoW
    row_width_as_per_record_m    NUMERIC(8,2),   -- old form's 'row_apr' — genuinely separate
                                                    -- value, not a duplicate of row_width_m
                                                    -- (Section 1.5 reconciliation)
    carriageway_width_m          NUMERIC(8,2),
    num_lanes                    SMALLINT,

    footpath_left_avail          BOOLEAN,
    footpath_left_width_m        NUMERIC(6,2),
    footpath_right_avail         BOOLEAN,
    footpath_right_width_m       NUMERIC(6,2),

    median_avail                 BOOLEAN,
    median_width_m               NUMERIC(6,2),
    median_paved_or_green        VARCHAR(32),

    shoulder_left_avail          BOOLEAN,
    shoulder_left_width_m        NUMERIC(6,2),
    shoulder_right_avail         BOOLEAN,
    shoulder_right_width_m       NUMERIC(6,2),

    verge_avail                  BOOLEAN,
    verge_type                   VARCHAR(64),

    drain_left_avail             BOOLEAN,
    drain_right_avail            BOOLEAN,

    data_source                  VARCHAR(32) NOT NULL DEFAULT 'primary_db_import'
                                   CHECK (data_source IN ('primary_db_import','field_created','field_corrected')),
    qa_status                    VARCHAR(32) NOT NULL DEFAULT 'pending_field_verification'
                                   CHECK (qa_status IN ('pending_field_verification','field_verified','flagged')),
    surveyor_id                  UUID,
    created_at                   TIMESTAMP NOT NULL DEFAULT now(),
    updated_at                   TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX idx_road_geometry_road_id ON road_geometry (road_id);

-- ============================================================================
-- 2.3  pavement  (road_id FK, 1:1)
-- ============================================================================
CREATE TABLE pavement (
    pavement_id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    road_id                      VARCHAR(64) NOT NULL UNIQUE REFERENCES road_inventory(road_id),
    nagar_nigam_id                VARCHAR(32) NOT NULL DEFAULT 'GNN',

    pavement_type                 VARCHAR(64)
                                    CHECK (pavement_type IN ('Bituminous','Cement Concrete',
                                      'Interlocking Paver Block','WBM/Granular','Earthen/Kuccha',
                                      'Mixed','Other')),
    pavement_condition            VARCHAR(32)
                                    CHECK (pavement_condition IN ('Good','Fair','Poor','Very Poor')),
    material_class                 VARCHAR(128),  -- old form's 'material_c' — carried through as
                                                     -- a secondary reference field only

    data_source                   VARCHAR(32) NOT NULL DEFAULT 'primary_db_import'
                                    CHECK (data_source IN ('primary_db_import','field_created','field_corrected')),
    qa_status                     VARCHAR(32) NOT NULL DEFAULT 'pending_field_verification'
                                    CHECK (qa_status IN ('pending_field_verification','field_verified','flagged')),
    surveyor_id                   UUID,
    created_at                    TIMESTAMP NOT NULL DEFAULT now(),
    updated_at                    TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX idx_pavement_road_id ON pavement (road_id);

-- ============================================================================
-- 2.4  pavement_distress  (road_id FK, 1:many, own geometry)
-- ============================================================================
CREATE TABLE pavement_distress (
    distress_id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    road_id                       VARCHAR(64) NOT NULL REFERENCES road_inventory(road_id),
    nagar_nigam_id                 VARCHAR(32) NOT NULL DEFAULT 'GNN',

    distress_type                  VARCHAR(64)
                                     CHECK (distress_type IN ('Pothole','Crack','Damaged Paver Block',
                                       'Uneven Surface','Waterlogging Damage','Rutting','Other')),
    severity                       VARCHAR(32),
    approx_length_m                NUMERIC(8,2),
    approx_width_m                 NUMERIC(8,2),
    approx_area_sqm                NUMERIC(10,2) GENERATED ALWAYS AS (approx_length_m * approx_width_m) STORED,

    geom                            geometry(Geometry, 4326) NOT NULL,  -- Point or Polygon per instance
    remarks                         TEXT,

    data_source                     VARCHAR(32) NOT NULL DEFAULT 'field_created'
                                      CHECK (data_source IN ('primary_db_import','field_created','field_corrected')),
    qa_status                       VARCHAR(32) NOT NULL DEFAULT 'field_verified'
                                      CHECK (qa_status IN ('pending_field_verification','field_verified','flagged')),
    gps_captured_at                 TIMESTAMP,
    surveyor_id                     UUID,
    created_at                      TIMESTAMP NOT NULL DEFAULT now(),
    updated_at                      TIMESTAMP NOT NULL DEFAULT now(),

    CONSTRAINT chk_pavement_distress_geom_type
        CHECK (GeometryType(geom) IN ('POINT','POLYGON'))
);

CREATE INDEX idx_pavement_distress_road_id ON pavement_distress (road_id);
CREATE INDEX idx_pavement_distress_geom ON pavement_distress USING GIST (geom);

-- ============================================================================
-- 2.5  drainage  (road_id FK, 1:many — left/right/both, differing types)
-- Seeded from nv_allnndb.ghaziabad.ghaziabad_drain (27,678 records) via a
-- one-time spatial nearest-road join — see docs/gnn-survey/03-data-reuse.md
-- ============================================================================
CREATE TABLE drainage (
    drain_id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    road_id                         VARCHAR(64) NOT NULL REFERENCES road_inventory(road_id),
    nagar_nigam_id                   VARCHAR(32) NOT NULL DEFAULT 'GNN',

    side                             VARCHAR(16) CHECK (side IN ('Left','Right','Both')),
    drain_type                       VARCHAR(64),
    material                         VARCHAR(64),  -- real gap found in Section 1.5 — both the old
                                                      -- Flutter form's 'drain_mtrl' and
                                                      -- ghaziabad_drain's own 'material' column
                                                      -- (e.g. 'Bricked') needed this
    availability                     BOOLEAN,
    continuity                       VARCHAR(32),
    width_m                          NUMERIC(6,2),
    depth_m                          NUMERIC(6,2),
    length_m                         NUMERIC(10,2),
    covered                          BOOLEAN,
    cover_width_m                    NUMERIC(6,2),
    blockage                         BOOLEAN,
    damage                           BOOLEAN,
    affected_length_m                NUMERIC(10,2),
    physical_condition                VARCHAR(32),

    -- Section 3: topology placeholders for a future drain-network graph
    from_node_id                      VARCHAR(64),
    to_node_id                        VARCHAR(64),
    upstream_connection                UUID REFERENCES drainage(drain_id),
    downstream_connection              UUID REFERENCES drainage(drain_id),

    geom                              geometry(LineString, 4326),
    remarks                           TEXT,

    data_source                       VARCHAR(32) NOT NULL DEFAULT 'primary_db_import'
                                        CHECK (data_source IN ('primary_db_import','field_created','field_corrected')),
    qa_status                         VARCHAR(32) NOT NULL DEFAULT 'pending_field_verification'
                                        CHECK (qa_status IN ('pending_field_verification','field_verified','flagged')),
    surveyor_id                       UUID,
    created_at                        TIMESTAMP NOT NULL DEFAULT now(),
    updated_at                        TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX idx_drainage_road_id ON drainage (road_id);
CREATE INDEX idx_drainage_geom ON drainage USING GIST (geom);

-- ============================================================================
-- 2.6  footpath  (road_id FK, 1:many — left/right)
-- ============================================================================
CREATE TABLE footpath (
    footpath_id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    road_id                           VARCHAR(64) NOT NULL REFERENCES road_inventory(road_id),
    nagar_nigam_id                     VARCHAR(32) NOT NULL DEFAULT 'GNN',

    side                               VARCHAR(16) CHECK (side IN ('Left','Right')),
    available                          BOOLEAN,
    width_m                            NUMERIC(6,2),
    surface_material                   VARCHAR(64),
    condition                          VARCHAR(32),
    paved_length_m                     NUMERIC(10,2),
    greened_length_m                   NUMERIC(10,2),
    to_be_paved                        BOOLEAN DEFAULT false,   -- gap #3 vs. Excel, first revision
    to_be_greened                      BOOLEAN DEFAULT false,
    encroachment                       BOOLEAN,
    obstruction                        BOOLEAN,

    geom                                geometry(LineString, 4326),
    remarks                            TEXT,

    data_source                        VARCHAR(32) NOT NULL DEFAULT 'field_created'
                                         CHECK (data_source IN ('primary_db_import','field_created','field_corrected')),
    qa_status                          VARCHAR(32) NOT NULL DEFAULT 'field_verified'
                                         CHECK (qa_status IN ('pending_field_verification','field_verified','flagged')),
    surveyor_id                        UUID,
    created_at                         TIMESTAMP NOT NULL DEFAULT now(),
    updated_at                         TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX idx_footpath_road_id ON footpath (road_id);
CREATE INDEX idx_footpath_geom ON footpath USING GIST (geom);

-- ============================================================================
-- 2.7  median_verge  (road_id FK, 1:many)
-- ============================================================================
CREATE TABLE median_verge (
    median_id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    road_id                            VARCHAR(64) NOT NULL REFERENCES road_inventory(road_id),
    nagar_nigam_id                      VARCHAR(32) NOT NULL DEFAULT 'GNN',

    available                           BOOLEAN,
    median_type                         VARCHAR(64),
    width_m                             NUMERIC(6,2),
    length_m                            NUMERIC(10,2),
    paved                               BOOLEAN,
    green_cover                         BOOLEAN,
    greened_length_m                    NUMERIC(10,2),
    to_be_greened                       BOOLEAN DEFAULT false,
    condition                           VARCHAR(32),

    geom                                 geometry(Geometry, 4326),  -- LineString, or Polygon for wide medians
    remarks                             TEXT,

    data_source                         VARCHAR(32) NOT NULL DEFAULT 'field_created'
                                          CHECK (data_source IN ('primary_db_import','field_created','field_corrected')),
    qa_status                           VARCHAR(32) NOT NULL DEFAULT 'field_verified'
                                          CHECK (qa_status IN ('pending_field_verification','field_verified','flagged')),
    surveyor_id                         UUID,
    created_at                          TIMESTAMP NOT NULL DEFAULT now(),
    updated_at                          TIMESTAMP NOT NULL DEFAULT now(),

    CONSTRAINT chk_median_verge_geom_type
        CHECK (geom IS NULL OR GeometryType(geom) IN ('LINESTRING','POLYGON'))
);

CREATE INDEX idx_median_verge_road_id ON median_verge (road_id);
CREATE INDEX idx_median_verge_geom ON median_verge USING GIST (geom);

-- ============================================================================
-- 2.8  road_markings  (road_id FK, 1:many — mixed line/point)
-- ============================================================================
CREATE TABLE road_markings (
    marking_id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    road_id                             VARCHAR(64) NOT NULL REFERENCES road_inventory(road_id),
    nagar_nigam_id                       VARCHAR(32) NOT NULL DEFAULT 'GNN',

    marking_type                         VARCHAR(64)
                                           CHECK (marking_type IN ('Centre Line','Edge Line','Lane Marking',
                                             'Zebra Crossing','Stop Line','Direction Arrow',
                                             'Median Marking','Other')),
    location_side                        VARCHAR(32),
    available                            BOOLEAN,
    condition                            VARCHAR(32),
    visibility                           VARCHAR(32),
    length_m                             NUMERIC(10,2),

    -- Shape genuinely varies by marking_type (centre line = Line, stop line/zebra
    -- crossing = Point or short Polygon). A hard SQL CHECK mapping every type to its
    -- exact expected shape is fragile to maintain (a new marking_type value would
    -- need a matching CHECK edit) — kept as a light CHECK here (any of the three
    -- plausible shapes), with the specific type-to-shape rule enforced in the
    -- backend/app validation layer instead, per docs/gnn-survey/04-backend.md.
    geom                                  geometry(Geometry, 4326) NOT NULL,
    remarks                              TEXT,

    data_source                          VARCHAR(32) NOT NULL DEFAULT 'field_created'
                                           CHECK (data_source IN ('primary_db_import','field_created','field_corrected')),
    qa_status                            VARCHAR(32) NOT NULL DEFAULT 'field_verified'
                                           CHECK (qa_status IN ('pending_field_verification','field_verified','flagged')),
    surveyor_id                          UUID,
    created_at                           TIMESTAMP NOT NULL DEFAULT now(),
    updated_at                           TIMESTAMP NOT NULL DEFAULT now(),

    CONSTRAINT chk_road_markings_geom_type
        CHECK (GeometryType(geom) IN ('POINT','LINESTRING','POLYGON'))
);

CREATE INDEX idx_road_markings_road_id ON road_markings (road_id);
CREATE INDEX idx_road_markings_geom ON road_markings USING GIST (geom);

-- ============================================================================
-- 2.9  road_signage  (road_id FK, 1:many, Point)
-- ============================================================================
CREATE TABLE road_signage (
    sign_id                              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    road_id                              VARCHAR(64) NOT NULL REFERENCES road_inventory(road_id),
    nagar_nigam_id                        VARCHAR(32) NOT NULL DEFAULT 'GNN',

    sign_type                             VARCHAR(128),
    sign_category                         VARCHAR(64)
                                            CHECK (sign_category IN ('Regulatory','Warning','Informatory',
                                              'Directional','Parking','Speed Limit','School Zone','Other')),
    side                                  VARCHAR(32),
    condition                             VARCHAR(32),
    visibility                            VARCHAR(32),
    reflective                            BOOLEAN,
    pole_condition                         VARCHAR(32),

    geom                                   geometry(Point, 4326) NOT NULL,
    remarks                               TEXT,

    data_source                           VARCHAR(32) NOT NULL DEFAULT 'field_created'
                                            CHECK (data_source IN ('primary_db_import','field_created','field_corrected')),
    qa_status                             VARCHAR(32) NOT NULL DEFAULT 'field_verified'
                                            CHECK (qa_status IN ('pending_field_verification','field_verified','flagged')),
    surveyor_id                           UUID,
    created_at                            TIMESTAMP NOT NULL DEFAULT now(),
    updated_at                            TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX idx_road_signage_road_id ON road_signage (road_id);
CREATE INDEX idx_road_signage_geom ON road_signage USING GIST (geom);

-- ============================================================================
-- 2.10  traffic_safety_features  (road_id FK, 1:many, Point/Line)
-- ============================================================================
CREATE TABLE traffic_safety_features (
    feature_id                            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    road_id                               VARCHAR(64) NOT NULL REFERENCES road_inventory(road_id),
    nagar_nigam_id                         VARCHAR(32) NOT NULL DEFAULT 'GNN',

    safety_feature_type                    VARCHAR(64)
                                             CHECK (safety_feature_type IN ('Speed Breaker','Rumble Strip',
                                               'Traffic Signal','Crash Barrier','Guard Rail','Safety Railing',
                                               'Road Stud/Cat Eye','Delineator','Chevron',
                                               'Pedestrian Crossing','Reflector','Other')),
    side                                    VARCHAR(32),
    quantity_or_length                       NUMERIC(10,2),
    condition                               VARCHAR(32),
    functional                              BOOLEAN,
    visibility                              VARCHAR(32),

    geom                                     geometry(Geometry, 4326) NOT NULL,  -- Point or Line by type
    remarks                                 TEXT,

    data_source                             VARCHAR(32) NOT NULL DEFAULT 'field_created'
                                              CHECK (data_source IN ('primary_db_import','field_created','field_corrected')),
    qa_status                               VARCHAR(32) NOT NULL DEFAULT 'field_verified'
                                              CHECK (qa_status IN ('pending_field_verification','field_verified','flagged')),
    surveyor_id                             UUID,
    created_at                              TIMESTAMP NOT NULL DEFAULT now(),
    updated_at                              TIMESTAMP NOT NULL DEFAULT now(),

    CONSTRAINT chk_traffic_safety_geom_type
        CHECK (GeometryType(geom) IN ('POINT','LINESTRING'))
);

CREATE INDEX idx_traffic_safety_road_id ON traffic_safety_features (road_id);
CREATE INDEX idx_traffic_safety_geom ON traffic_safety_features USING GIST (geom);

-- ============================================================================
-- 2.11  roadside_assets_utilities  (road_id FK, 1:many, Point — Polygon for
-- Parking Area specifically; gap found in the Section 2.17 traceability check)
-- ============================================================================
CREATE TABLE roadside_assets_utilities (
    asset_id                                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    road_id                                 VARCHAR(64) NOT NULL REFERENCES road_inventory(road_id),
    nagar_nigam_id                           VARCHAR(32) NOT NULL DEFAULT 'GNN',

    asset_type                               VARCHAR(64)
                                               CHECK (asset_type IN ('Bus Stop','Parking Area','Public Toilet',
                                                 'Electric Pole','Transformer','Streetlight','Streetlight (Solar)',
                                                 'Utility Pole','Telecom Box','Manhole','Chamber','Signboard',
                                                 'Tree','Ring Main Unit','Hand Pump','Other')),
                                               -- 'Ring Main Unit', 'Hand Pump', and the Streetlight/Solar split
                                               -- were added after the Section 1.5 Flutter-form reconciliation
                                               -- ('rmu', 'hp_well', 'strt_slr_l' in the old form)
    ownership_agency                         VARCHAR(128),
    condition                                VARCHAR(32),
    functional                               BOOLEAN,
    side                                     VARCHAR(32),

    geom                                      geometry(Geometry, 4326) NOT NULL,  -- Point for everything
                                                                                    -- except Parking Area,
                                                                                    -- which may be a Polygon
    remarks                                  TEXT,

    data_source                              VARCHAR(32) NOT NULL DEFAULT 'field_created'
                                               CHECK (data_source IN ('primary_db_import','field_created','field_corrected')),
    qa_status                                VARCHAR(32) NOT NULL DEFAULT 'field_verified'
                                               CHECK (qa_status IN ('pending_field_verification','field_verified','flagged')),
    surveyor_id                              UUID,
    created_at                               TIMESTAMP NOT NULL DEFAULT now(),
    updated_at                               TIMESTAMP NOT NULL DEFAULT now(),

    CONSTRAINT chk_roadside_assets_geom_type
        CHECK (
            (asset_type = 'Parking Area' AND GeometryType(geom) IN ('POINT','POLYGON'))
            OR (asset_type <> 'Parking Area' AND GeometryType(geom) = 'POINT')
        )
);

CREATE INDEX idx_roadside_assets_road_id ON roadside_assets_utilities (road_id);
CREATE INDEX idx_roadside_assets_geom ON roadside_assets_utilities USING GIST (geom);

-- ============================================================================
-- 2.12  road_obstructions  (road_id FK, 1:many, Point/Polygon) — new table,
-- was the tender's single biggest gap in the original Excel spec
-- ============================================================================
CREATE TABLE road_obstructions (
    obstruction_id                            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    road_id                                   VARCHAR(64) NOT NULL REFERENCES road_inventory(road_id),
    nagar_nigam_id                             VARCHAR(32) NOT NULL DEFAULT 'GNN',

    obstruction_type                           VARCHAR(64)
                                                 CHECK (obstruction_type IN ('Unauthorized Ramp','Platform',
                                                   'Kiosk','Vending Area','Construction Material',
                                                   'Permanent Structure','Temporary Structure','Other')),
    side                                       VARCHAR(32),
    approx_length_m                            NUMERIC(8,2),
    approx_area_sqm                            NUMERIC(10,2),
    impact_on_movement                         VARCHAR(16)
                                                 CHECK (impact_on_movement IN ('None','Partial','Severe')),

    geom                                        geometry(Geometry, 4326) NOT NULL,
    remarks                                    TEXT,

    data_source                                VARCHAR(32) NOT NULL DEFAULT 'field_created'
                                                 CHECK (data_source IN ('primary_db_import','field_created','field_corrected')),
    qa_status                                  VARCHAR(32) NOT NULL DEFAULT 'field_verified'
                                                 CHECK (qa_status IN ('pending_field_verification','field_verified','flagged')),
    gps_captured_at                             TIMESTAMP,
    surveyor_id                                UUID,
    created_at                                 TIMESTAMP NOT NULL DEFAULT now(),
    updated_at                                 TIMESTAMP NOT NULL DEFAULT now(),

    CONSTRAINT chk_road_obstructions_geom_type
        CHECK (GeometryType(geom) IN ('POINT','POLYGON'))
);

CREATE INDEX idx_road_obstructions_road_id ON road_obstructions (road_id);
CREATE INDEX idx_road_obstructions_geom ON road_obstructions USING GIST (geom);

-- ============================================================================
-- 5.1  users  (built fresh — old system has no role/active concept at all)
-- ============================================================================
CREATE TABLE users (
    user_id                                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- org_type distinguishes WHO the account belongs to; role (below) distinguishes
    -- WHAT they can do — the two are independent dimensions. RSAC (state-level oversight
    -- body) accounts are not fixed to one city; Nagar Nigam accounts (e.g. Ghaziabad's own
    -- surveyors/reviewers/admins) are permanently fixed to the one city on their profile.
    org_type                                    VARCHAR(16) NOT NULL DEFAULT 'NAGAR_NIGAM'
                                                  CHECK (org_type IN ('RSAC','NAGAR_NIGAM')),
    nagar_nigam_id                              VARCHAR(32),   -- REQUIRED and fixed for
                                                                 -- NAGAR_NIGAM accounts; NULL for
                                                                 -- RSAC accounts, who pick a city
                                                                 -- per session instead (see
                                                                 -- survey_sessions.active_nagar_nigam_id)

    name                                        VARCHAR(255) NOT NULL,
    designation                                 VARCHAR(128),
    username                                    VARCHAR(64) NOT NULL UNIQUE,
    password_hash                               VARCHAR(255) NOT NULL,
    email                                       VARCHAR(255),
    phone_no                                    VARCHAR(20),

    role                                        VARCHAR(16) NOT NULL
                                                  CHECK (role IN ('ADMIN','SURVEYOR','REVIEWER')),
    active                                      BOOLEAN NOT NULL DEFAULT true,  -- soft-delete only,
                                                                                  -- never a hard DELETE
                                                                                  -- (preserves FK
                                                                                  -- integrity with
                                                                                  -- every submission)
    created_by                                  UUID REFERENCES users(user_id),

    created_at                                  TIMESTAMP NOT NULL DEFAULT now(),
    updated_at                                  TIMESTAMP NOT NULL DEFAULT now(),
    deactivated_at                              TIMESTAMP,

    CONSTRAINT chk_users_city_scope CHECK (
        (org_type = 'NAGAR_NIGAM' AND nagar_nigam_id IS NOT NULL)
        OR (org_type = 'RSAC' AND nagar_nigam_id IS NULL)
    )
);

CREATE INDEX idx_users_role ON users (role);
CREATE INDEX idx_users_active ON users (active);
CREATE INDEX idx_users_org_type ON users (org_type);

-- Now that users exists, wire up the surveyor_id FKs deferred above.
ALTER TABLE road_inventory            ADD CONSTRAINT fk_road_inventory_surveyor            FOREIGN KEY (surveyor_id) REFERENCES users(user_id);
ALTER TABLE road_geometry             ADD CONSTRAINT fk_road_geometry_surveyor             FOREIGN KEY (surveyor_id) REFERENCES users(user_id);
ALTER TABLE pavement                  ADD CONSTRAINT fk_pavement_surveyor                  FOREIGN KEY (surveyor_id) REFERENCES users(user_id);
ALTER TABLE pavement_distress         ADD CONSTRAINT fk_pavement_distress_surveyor         FOREIGN KEY (surveyor_id) REFERENCES users(user_id);
ALTER TABLE drainage                  ADD CONSTRAINT fk_drainage_surveyor                  FOREIGN KEY (surveyor_id) REFERENCES users(user_id);
ALTER TABLE footpath                  ADD CONSTRAINT fk_footpath_surveyor                  FOREIGN KEY (surveyor_id) REFERENCES users(user_id);
ALTER TABLE median_verge              ADD CONSTRAINT fk_median_verge_surveyor              FOREIGN KEY (surveyor_id) REFERENCES users(user_id);
ALTER TABLE road_markings             ADD CONSTRAINT fk_road_markings_surveyor             FOREIGN KEY (surveyor_id) REFERENCES users(user_id);
ALTER TABLE road_signage              ADD CONSTRAINT fk_road_signage_surveyor              FOREIGN KEY (surveyor_id) REFERENCES users(user_id);
ALTER TABLE traffic_safety_features   ADD CONSTRAINT fk_traffic_safety_surveyor            FOREIGN KEY (surveyor_id) REFERENCES users(user_id);
ALTER TABLE roadside_assets_utilities ADD CONSTRAINT fk_roadside_assets_surveyor           FOREIGN KEY (surveyor_id) REFERENCES users(user_id);
ALTER TABLE road_obstructions         ADD CONSTRAINT fk_road_obstructions_surveyor         FOREIGN KEY (surveyor_id) REFERENCES users(user_id);

-- ============================================================================
-- 6.1  survey_sessions  (heartbeat-based activity tracking — Section 6)
-- ============================================================================
CREATE TABLE survey_sessions (
    session_id                                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                                     UUID NOT NULL REFERENCES users(user_id),
    device_id                                   VARCHAR(128),
    app_version                                 VARCHAR(32),

    -- Which city this session is scoped to. For a NAGAR_NIGAM user this always equals
    -- their fixed users.nagar_nigam_id (set at login, never changed mid-session). For an
    -- RSAC user, whichever city they picked at login — every row/query this session
    -- touches is scoped to this value, not to anything stored on the user profile, and it
    -- can be a different city the next time the same RSAC user logs in.
    active_nagar_nigam_id                       VARCHAR(32) NOT NULL,

    -- Which survey module this session is working in — so two people can survey the
    -- same road at the same time without collision: one doing ROAD_DIRECTORY_UPDATE,
    -- another DRAIN_UPDATE, another the new tender's ROAD_INVENTORY_SURVEY (the
    -- 12-layer survey, Section 2). Chosen once at login, not switchable mid-session —
    -- picking up a different module means logging in again (a new session), same
    -- principle as active_nagar_nigam_id above.
    module                                      VARCHAR(32) NOT NULL
                                                  CHECK (module IN ('ROAD_DIRECTORY_UPDATE','DRAIN_UPDATE','ROAD_INVENTORY_SURVEY')),

    login_at                                    TIMESTAMP NOT NULL DEFAULT now(),
    logout_at                                   TIMESTAMP,
    last_heartbeat_at                           TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX idx_survey_sessions_user_id ON survey_sessions (user_id);
CREATE INDEX idx_survey_sessions_last_heartbeat ON survey_sessions (last_heartbeat_at);
CREATE INDEX idx_survey_sessions_active_city ON survey_sessions (active_nagar_nigam_id);

-- ============================================================================
-- 2.13  survey_media  (photo/video indexing, multi-photo, geotag metadata)
-- ============================================================================
CREATE TABLE survey_media (
    media_id                                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    road_id                                      VARCHAR(64) NOT NULL REFERENCES road_inventory(road_id),
                                                   -- always present, even for sub-point media, so
                                                   -- "all photos for this road" is one indexed query

    parent_table                                 VARCHAR(64) NOT NULL,  -- e.g. 'pavement_distress',
                                                                          -- 'drainage', 'road_obstructions'
    parent_id                                    UUID NOT NULL,          -- the specific row's PK in
                                                                          -- that table (exact sub-point)

    media_type                                   VARCHAR(8) NOT NULL CHECK (media_type IN ('photo','video')),
    file_url                                     VARCHAR(1024) NOT NULL,  -- MinIO object URL (gnn-survey-minio)

    captured_at                                  TIMESTAMP NOT NULL,
    gps_lat                                      DOUBLE PRECISION,
    gps_long                                     DOUBLE PRECISION,
    gps_accuracy_m                               NUMERIC(6,2),
    compass_heading                              NUMERIC(5,2),

    overlay_applied                              BOOLEAN NOT NULL DEFAULT false,  -- geotag footer
                                                                                     -- burned onto image
    exif_geotagged                               BOOLEAN NOT NULL DEFAULT false,  -- GPS EXIF tags written

    surveyor_id                                  UUID REFERENCES users(user_id),
    upload_status                                VARCHAR(16) NOT NULL DEFAULT 'pending'
                                                   CHECK (upload_status IN ('pending','uploaded','failed')),

    created_at                                   TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX idx_survey_media_road_id ON survey_media (road_id);
CREATE INDEX idx_survey_media_parent ON survey_media (parent_table, parent_id);

-- ============================================================================
-- 2.15  ward_boundary / zone_boundary  (copied from ghaziabad_ward_boundary /
-- ghaziabad_zone_boundary, plus nagar_nigam_id for future multi-city reuse)
-- ============================================================================
CREATE TABLE ward_boundary (
    ward_boundary_id                             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nagar_nigam_id                                VARCHAR(32) NOT NULL DEFAULT 'GNN',
    ward_no                                      VARCHAR(32),
    ward_name                                    VARCHAR(255),
    geom                                          geometry(MultiPolygon, 4326) NOT NULL
);

CREATE INDEX idx_ward_boundary_geom ON ward_boundary USING GIST (geom);

CREATE TABLE zone_boundary (
    zone_boundary_id                              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nagar_nigam_id                                 VARCHAR(32) NOT NULL DEFAULT 'GNN',
    zone_no                                       VARCHAR(32),
    zone_name                                     VARCHAR(255),
    geom                                           geometry(MultiPolygon, 4326) NOT NULL
);

CREATE INDEX idx_zone_boundary_geom ON zone_boundary USING GIST (geom);

-- ============================================================================
-- 6.3  daily_survey_summary  — derived VIEW, not a hand-maintained table.
-- Unions the surveyor_id/created_at/road_id triple across every field-capture
-- table (road_inventory/road_geometry/pavement excluded here since they're
-- 1:1 baseline records mostly touched during import, not daily field work;
-- included the nine 1:many field-capture tables that represent actual daily
-- survey output).
-- ============================================================================
CREATE VIEW daily_survey_summary AS
SELECT surveyor_id AS user_id,
       DATE(created_at) AS survey_date,
       MIN(created_at) AS day_start,
       MAX(created_at) AS day_end,
       COUNT(*) AS submissions_count,
       COUNT(DISTINCT road_id) AS roads_covered
FROM (
    SELECT surveyor_id, created_at, road_id FROM pavement_distress
    UNION ALL SELECT surveyor_id, created_at, road_id FROM drainage
    UNION ALL SELECT surveyor_id, created_at, road_id FROM footpath
    UNION ALL SELECT surveyor_id, created_at, road_id FROM median_verge
    UNION ALL SELECT surveyor_id, created_at, road_id FROM road_markings
    UNION ALL SELECT surveyor_id, created_at, road_id FROM road_signage
    UNION ALL SELECT surveyor_id, created_at, road_id FROM traffic_safety_features
    UNION ALL SELECT surveyor_id, created_at, road_id FROM roadside_assets_utilities
    UNION ALL SELECT surveyor_id, created_at, road_id FROM road_obstructions
) all_submissions
WHERE surveyor_id IS NOT NULL
GROUP BY surveyor_id, DATE(created_at);

-- ============================================================================
-- End of 001_init_schema.sql
-- Next: 002_import_from_primary_db.sql (Section 4 one-time import — written
-- separately once this schema is reviewed and applied).
-- ============================================================================
