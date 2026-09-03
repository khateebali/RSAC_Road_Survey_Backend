# GNN Road Survey Backend

Spring Boot backend for the Ghaziabad Nagar Nigam (GNN) road inventory survey project
(Tender Ref: 129/Nirman/2026-27).

Own database (`gnn_road_survey` on `db-primary`), own MinIO object store
(`gnn-survey-minio` on `staging-db`, port 9002/9003), deployed standalone on `staging-db`
port 8070 — fully independent of the existing `LKO_NN` backend.

See the architecture plan for full details: `docs/gnn-survey/` (added as the project is built
out).
