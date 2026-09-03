package com.gnn.roadsurvey.entity;

import javax.persistence.*;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Mirrors db/schema/001_init_schema.sql section 5.1.
 *
 * org_type and role are independent dimensions: org_type says WHO the account
 * belongs to (RSAC = state oversight, city chosen per session; NAGAR_NIGAM =
 * one city fixed permanently on the profile), role says WHAT they can do
 * (ADMIN/SURVEYOR/REVIEWER). The DB-level CHECK constraint pairing org_type
 * with nagarNigamId is the source of truth — this entity doesn't re-enforce
 * it, so a violation surfaces as a DB error, not a silently accepted row.
 */
@Entity
@Table(name = "users")
public class User {

    @Id
    @GeneratedValue
    @Column(name = "user_id")
    private UUID userId;

    @Enumerated(EnumType.STRING)
    @Column(name = "org_type", nullable = false)
    private OrgType orgType = OrgType.NAGAR_NIGAM;

    // Required + fixed when orgType = NAGAR_NIGAM; null when orgType = RSAC.
    @Column(name = "nagar_nigam_id")
    private String nagarNigamId;

    @Column(nullable = false)
    private String name;

    private String designation;

    @Column(nullable = false, unique = true)
    private String username;

    @Column(name = "password_hash", nullable = false)
    private String passwordHash;

    private String email;

    @Column(name = "phone_no")
    private String phoneNo;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private UserRole role;

    @Column(nullable = false)
    private boolean active = true;

    @Column(name = "created_by")
    private UUID createdBy;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @Column(name = "deactivated_at")
    private LocalDateTime deactivatedAt;

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

    public UUID getUserId() { return userId; }

    public OrgType getOrgType() { return orgType; }
    public void setOrgType(OrgType orgType) { this.orgType = orgType; }

    public String getNagarNigamId() { return nagarNigamId; }
    public void setNagarNigamId(String nagarNigamId) { this.nagarNigamId = nagarNigamId; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getDesignation() { return designation; }
    public void setDesignation(String designation) { this.designation = designation; }

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public String getPasswordHash() { return passwordHash; }
    public void setPasswordHash(String passwordHash) { this.passwordHash = passwordHash; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getPhoneNo() { return phoneNo; }
    public void setPhoneNo(String phoneNo) { this.phoneNo = phoneNo; }

    public UserRole getRole() { return role; }
    public void setRole(UserRole role) { this.role = role; }

    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }

    public UUID getCreatedBy() { return createdBy; }
    public void setCreatedBy(UUID createdBy) { this.createdBy = createdBy; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }

    public LocalDateTime getDeactivatedAt() { return deactivatedAt; }
    public void setDeactivatedAt(LocalDateTime deactivatedAt) { this.deactivatedAt = deactivatedAt; }
}
