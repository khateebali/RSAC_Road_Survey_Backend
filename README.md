# GNN Road Survey Backend

Spring Boot backend for the Ghaziabad Nagar Nigam (GNN) road inventory survey project
(Tender Ref: 129/Nirman/2026-27).

Own database (`gnn_road_survey` on `db-primary`), own MinIO object store
(`gnn-survey-minio` on `staging-db`, port 9002/9003), deployed standalone on `staging-db`
port 8070 — fully independent of the existing `LKO_NN` backend.

See the architecture plan for full details: `docs/gnn-survey/` (added as the project is built
out).

## Status

Phase 1 scaffold in progress:
- `db/schema/001_init_schema.sql` — full DDL (16 tables + 1 view), reviewed, not yet applied
  to a real database.
- Spring Boot skeleton (Maven, Java 17, runnable jar with embedded Tomcat — unlike LKO_NN,
  which is a WAR under an external Tomcat, since this service is deployed standalone):
  - Auth: JWT login/heartbeat/logout, implementing the RSAC-vs-Nagar-Nigam city-scoping model
    (Section 5 of the plan) — a NAGAR_NIGAM account's session city comes from its fixed
    profile; an RSAC account must pick a city at login, carried for that session's lifetime
    via `survey_sessions.active_nagar_nigam_id` and the JWT's `activeNagarNigamId` claim.
  - `RequireAuth`/`AuthInterceptor` — same pattern as LKO_NN's, extended with role-scoping and
    heartbeat-based idle expiry (30 min, Section 6.2).
  - `RoadInventory` entity + repository as the reference pattern for the remaining 11 survey
    tables (`road_geometry`, `pavement`, `pavement_distress`, `drainage`, `footpath`,
    `median_verge`, `road_markings`, `road_signage`, `traffic_safety_features`,
    `roadside_assets_utilities`, `road_obstructions`) — mechanical translations of the DDL,
    not yet written.
  - `springdoc-openapi` wired in (Section 7.1) — `/swagger-ui.html` once the service is
    running, for a real API contract as more endpoints are added.
  - Actuator + Micrometer Prometheus registry wired in (Section 7.1) for `/actuator/prometheus`.

**Not yet built**: entities/repositories for the remaining 11 survey tables + `SurveyMedia` +
`WardBoundary`/`ZoneBoundary`; controllers/services beyond auth; `002_import_from_primary_db.sql`;
admin user-management endpoints; media upload (MinIO) wiring.

Compiles clean via `./mvnw compile` (Maven wrapper copied from LKO_NN's, same version).
