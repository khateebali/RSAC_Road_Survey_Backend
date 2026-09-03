package com.gnn.roadsurvey.dto;

public class AuthResponse {

    private String token;
    private String userId;
    private String name;
    private String role;
    private String orgType;
    private String activeNagarNigamId;
    private String module;

    public AuthResponse(String token, String userId, String name, String role,
                         String orgType, String activeNagarNigamId, String module) {
        this.token = token;
        this.userId = userId;
        this.name = name;
        this.role = role;
        this.orgType = orgType;
        this.activeNagarNigamId = activeNagarNigamId;
        this.module = module;
    }

    public String getToken() { return token; }
    public String getUserId() { return userId; }
    public String getName() { return name; }
    public String getRole() { return role; }
    public String getOrgType() { return orgType; }
    public String getActiveNagarNigamId() { return activeNagarNigamId; }
    public String getModule() { return module; }
}
