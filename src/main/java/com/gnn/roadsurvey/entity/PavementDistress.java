package com.gnn.roadsurvey.entity;

import org.locationtech.jts.geom.Geometry;

import javax.persistence.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Mirrors db/schema/001_init_schema.sql section 2.4. approxAreaSqm is a
 * DB-generated column (STORED) — never set from Java, only read back.
 */
@Entity
@Table(name = "pavement_distress")
public class PavementDistress {

    @Id
    @GeneratedValue
    @Column(name = "distress_id")
    private UUID distressId;

    @Column(name = "road_id", nullable = false)
    private String roadId;

    @Column(name = "nagar_nigam_id", nullable = false)
    private String nagarNigamId = "GNN";

    @Column(name = "distress_type", nullable = false)
    private String distressType;

    private String severity;

    @Column(name = "approx_length_m")
    private BigDecimal approxLengthM;

    @Column(name = "approx_width_m")
    private BigDecimal approxWidthM;

    @Column(name = "approx_area_sqm", insertable = false, updatable = false)
    private BigDecimal approxAreaSqm;

    @Column(columnDefinition = "geometry(Geometry,4326)", nullable = false)
    private Geometry geom;

    private String remarks;

    @Column(name = "data_source", nullable = false)
    private String dataSource = "field_created";

    @Column(name = "qa_status", nullable = false)
    private String qaStatus = "field_verified";

    @Column(name = "gps_captured_at")
    private LocalDateTime gpsCapturedAt;

    @Column(name = "surveyor_id")
    private UUID surveyorId;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = createdAt;
    }

    @PreUpdate
    void onUpdate() {
        updatedAt = LocalDateTime.now();
    }

    // --- getters/setters ---

    public UUID getDistressId() { return distressId; }

    public String getRoadId() { return roadId; }
    public void setRoadId(String roadId) { this.roadId = roadId; }

    public String getNagarNigamId() { return nagarNigamId; }
    public void setNagarNigamId(String nagarNigamId) { this.nagarNigamId = nagarNigamId; }

    public String getDistressType() { return distressType; }
    public void setDistressType(String distressType) { this.distressType = distressType; }

    public String getSeverity() { return severity; }
    public void setSeverity(String severity) { this.severity = severity; }

    public BigDecimal getApproxLengthM() { return approxLengthM; }
    public void setApproxLengthM(BigDecimal approxLengthM) { this.approxLengthM = approxLengthM; }

    public BigDecimal getApproxWidthM() { return approxWidthM; }
    public void setApproxWidthM(BigDecimal approxWidthM) { this.approxWidthM = approxWidthM; }

    public BigDecimal getApproxAreaSqm() { return approxAreaSqm; }

    public Geometry getGeom() { return geom; }
    public void setGeom(Geometry geom) { this.geom = geom; }

    public String getRemarks() { return remarks; }
    public void setRemarks(String remarks) { this.remarks = remarks; }

    public String getDataSource() { return dataSource; }
    public void setDataSource(String dataSource) { this.dataSource = dataSource; }

    public String getQaStatus() { return qaStatus; }
    public void setQaStatus(String qaStatus) { this.qaStatus = qaStatus; }

    public LocalDateTime getGpsCapturedAt() { return gpsCapturedAt; }
    public void setGpsCapturedAt(LocalDateTime gpsCapturedAt) { this.gpsCapturedAt = gpsCapturedAt; }

    public UUID getSurveyorId() { return surveyorId; }
    public void setSurveyorId(UUID surveyorId) { this.surveyorId = surveyorId; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}
