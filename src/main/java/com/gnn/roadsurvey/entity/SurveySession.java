package com.gnn.roadsurvey.entity;

import javax.persistence.*;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Mirrors db/schema/001_init_schema.sql section 6.1.
 *
 * activeNagarNigamId is the actual per-request city scope for this session —
 * for a NAGAR_NIGAM user it always equals their fixed users.nagarNigamId; for
 * an RSAC user it's whichever city they picked at login. Every query this
 * session's requests make must be scoped from this field (via the JWT claim
 * embedded at login, see JwtUtil), never from a client-supplied parameter.
 */
@Entity
@Table(name = "survey_sessions")
public class SurveySession {

    @Id
    @GeneratedValue
    @Column(name = "session_id")
    private UUID sessionId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "device_id")
    private String deviceId;

    @Column(name = "app_version")
    private String appVersion;

    @Column(name = "active_nagar_nigam_id", nullable = false)
    private String activeNagarNigamId;

    @Column(name = "login_at", nullable = false, updatable = false)
    private LocalDateTime loginAt;

    @Column(name = "logout_at")
    private LocalDateTime logoutAt;

    @Column(name = "last_heartbeat_at", nullable = false)
    private LocalDateTime lastHeartbeatAt;

    @PrePersist
    void onCreate() {
        loginAt = LocalDateTime.now();
        lastHeartbeatAt = loginAt;
    }

    // --- getters/setters ---

    public UUID getSessionId() { return sessionId; }

    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }

    public String getDeviceId() { return deviceId; }
    public void setDeviceId(String deviceId) { this.deviceId = deviceId; }

    public String getAppVersion() { return appVersion; }
    public void setAppVersion(String appVersion) { this.appVersion = appVersion; }

    public String getActiveNagarNigamId() { return activeNagarNigamId; }
    public void setActiveNagarNigamId(String activeNagarNigamId) { this.activeNagarNigamId = activeNagarNigamId; }

    public LocalDateTime getLoginAt() { return loginAt; }

    public LocalDateTime getLogoutAt() { return logoutAt; }
    public void setLogoutAt(LocalDateTime logoutAt) { this.logoutAt = logoutAt; }

    public LocalDateTime getLastHeartbeatAt() { return lastHeartbeatAt; }
    public void setLastHeartbeatAt(LocalDateTime lastHeartbeatAt) { this.lastHeartbeatAt = lastHeartbeatAt; }
}
