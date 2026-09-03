package com.gnn.roadsurvey.dto;

import javax.validation.constraints.NotBlank;

public class LoginRequest {

    @NotBlank
    private String username;

    @NotBlank
    private String password;

    // Required only for RSAC accounts (they pick a city at login);
    // ignored for NAGAR_NIGAM accounts, whose city comes from their profile.
    private String requestedNagarNigamId;

    private String deviceId;
    private String appVersion;

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }

    public String getRequestedNagarNigamId() { return requestedNagarNigamId; }
    public void setRequestedNagarNigamId(String requestedNagarNigamId) { this.requestedNagarNigamId = requestedNagarNigamId; }

    public String getDeviceId() { return deviceId; }
    public void setDeviceId(String deviceId) { this.deviceId = deviceId; }

    public String getAppVersion() { return appVersion; }
    public void setAppVersion(String appVersion) { this.appVersion = appVersion; }
}
