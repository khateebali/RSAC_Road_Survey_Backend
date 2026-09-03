package com.gnn.roadsurvey.entity;

import org.locationtech.jts.geom.MultiLineString;
import org.locationtech.jts.geom.Point;

import javax.persistence.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Mirrors db/schema/001_init_schema.sql section 2.1 — the master road table,
 * seeded once from LKO_NN.ghaziabad_nn.ghaziabad_road_net (Section 4 import),
 * never read from/written back to it afterward.
 *
 * Geometry mapping follows the same org.locationtech.jts.geom + columnDefinition
 * convention already proven in LKO_NN's model.Road.
 */
@Entity
@Table(name = "road_inventory")
public class RoadInventory {

    @Id
    @Column(name = "road_id", length = 64)
    private String roadId;

    @Column(name = "nagar_nigam_id", nullable = false)
    private String nagarNigamId = "GNN";

    @Column(name = "road_name")
    private String roadName;

    @Column(name = "local_name")
    private String localName;

    @Column(name = "ward_no")
    private String wardNo;

    @Column(name = "ward_name")
    private String wardName;

    @Column(name = "zone_no")
    private String zoneNo;

    @Column(name = "zone_name")
    private String zoneName;

    private String locality;
    private String category;
    private String ownership;

    @Column(name = "own_class")
    private String ownClass;

    @Column(name = "maintaining_agency")
    private String maintainingAgency;

    @Column(name = "construction_scheme")
    private String constructionScheme;

    @Column(name = "year_of_construction")
    private Integer yearOfConstruction;

    @Column(name = "nearby_landmark")
    private String nearbyLandmark;

    @Column(name = "start_point", columnDefinition = "geometry(Point,4326)")
    private Point startPoint;

    @Column(name = "end_point", columnDefinition = "geometry(Point,4326)")
    private Point endPoint;

    @Column(columnDefinition = "geometry(MultiLineString,4326)", nullable = false)
    private MultiLineString geom;

    @Column(name = "length_m")
    private BigDecimal lengthM;

    @Column(name = "length_km")
    private BigDecimal lengthKm;

    @Column(name = "from_node_id")
    private String fromNodeId;

    @Column(name = "to_node_id")
    private String toNodeId;

    @Column(name = "data_source", nullable = false)
    private String dataSource = "primary_db_import";

    @Column(name = "qa_status", nullable = false)
    private String qaStatus = "pending_field_verification";

    @Column(name = "survey_date")
    private LocalDate surveyDate;

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

    public String getRoadId() { return roadId; }
    public void setRoadId(String roadId) { this.roadId = roadId; }

    public String getNagarNigamId() { return nagarNigamId; }
    public void setNagarNigamId(String nagarNigamId) { this.nagarNigamId = nagarNigamId; }

    public String getRoadName() { return roadName; }
    public void setRoadName(String roadName) { this.roadName = roadName; }

    public String getLocalName() { return localName; }
    public void setLocalName(String localName) { this.localName = localName; }

    public String getWardNo() { return wardNo; }
    public void setWardNo(String wardNo) { this.wardNo = wardNo; }

    public String getWardName() { return wardName; }
    public void setWardName(String wardName) { this.wardName = wardName; }

    public String getZoneNo() { return zoneNo; }
    public void setZoneNo(String zoneNo) { this.zoneNo = zoneNo; }

    public String getZoneName() { return zoneName; }
    public void setZoneName(String zoneName) { this.zoneName = zoneName; }

    public String getLocality() { return locality; }
    public void setLocality(String locality) { this.locality = locality; }

    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }

    public String getOwnership() { return ownership; }
    public void setOwnership(String ownership) { this.ownership = ownership; }

    public String getOwnClass() { return ownClass; }
    public void setOwnClass(String ownClass) { this.ownClass = ownClass; }

    public String getMaintainingAgency() { return maintainingAgency; }
    public void setMaintainingAgency(String maintainingAgency) { this.maintainingAgency = maintainingAgency; }

    public String getConstructionScheme() { return constructionScheme; }
    public void setConstructionScheme(String constructionScheme) { this.constructionScheme = constructionScheme; }

    public Integer getYearOfConstruction() { return yearOfConstruction; }
    public void setYearOfConstruction(Integer yearOfConstruction) { this.yearOfConstruction = yearOfConstruction; }

    public String getNearbyLandmark() { return nearbyLandmark; }
    public void setNearbyLandmark(String nearbyLandmark) { this.nearbyLandmark = nearbyLandmark; }

    public Point getStartPoint() { return startPoint; }
    public void setStartPoint(Point startPoint) { this.startPoint = startPoint; }

    public Point getEndPoint() { return endPoint; }
    public void setEndPoint(Point endPoint) { this.endPoint = endPoint; }

    public MultiLineString getGeom() { return geom; }
    public void setGeom(MultiLineString geom) { this.geom = geom; }

    public BigDecimal getLengthM() { return lengthM; }
    public void setLengthM(BigDecimal lengthM) { this.lengthM = lengthM; }

    public BigDecimal getLengthKm() { return lengthKm; }
    public void setLengthKm(BigDecimal lengthKm) { this.lengthKm = lengthKm; }

    public String getFromNodeId() { return fromNodeId; }
    public void setFromNodeId(String fromNodeId) { this.fromNodeId = fromNodeId; }

    public String getToNodeId() { return toNodeId; }
    public void setToNodeId(String toNodeId) { this.toNodeId = toNodeId; }

    public String getDataSource() { return dataSource; }
    public void setDataSource(String dataSource) { this.dataSource = dataSource; }

    public String getQaStatus() { return qaStatus; }
    public void setQaStatus(String qaStatus) { this.qaStatus = qaStatus; }

    public LocalDate getSurveyDate() { return surveyDate; }
    public void setSurveyDate(LocalDate surveyDate) { this.surveyDate = surveyDate; }

    public UUID getSurveyorId() { return surveyorId; }
    public void setSurveyorId(UUID surveyorId) { this.surveyorId = surveyorId; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}
