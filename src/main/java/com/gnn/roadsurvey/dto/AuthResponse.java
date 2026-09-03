package com.gnn.roadsurvey.dto;

public class AuthResponse {

    private String token;
    private String userId;
    private String name;
    private String role;
    private String orgType;
    private String activeNagarNigamId;

    public AuthResponse(String token, String userId, String name, String role,
                         String orgType, String activeNagarNigamId) {
        this.token = token;
        this.userId = userId;
        this.name = name;
        this.role = role;
        this.orgType = orgType;
        this.activeNagarNigamId = activeNagarNigamId;
    }

    public String getToken() { return token; }
    public String getUserId() { return userId; }
    public String getName() { return name; }
    public String getRole() { return role; }
    public String getOrgType() { return orgType; }
    public String getActiveNagarNigamId() { return activeNagarNigamId; }
}
