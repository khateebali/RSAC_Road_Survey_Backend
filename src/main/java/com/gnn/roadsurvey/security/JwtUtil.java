package com.gnn.roadsurvey.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.security.Key;
import java.util.Date;
import java.util.UUID;

/**
 * Same JWT pattern already proven in LKO_NN's util.JwtUtil, extended per
 * Section 5.3 of the plan: the token carries role, orgType and
 * activeNagarNigamId as claims, so every downstream request is scoped from
 * the token — never from a client-supplied city parameter — without a DB
 * round-trip just to know which city a request belongs to.
 */
@Component
public class JwtUtil {

    @Value("${jwt.secret}")
    private String jwtSecret;

    @Value("${jwt.expiration}")
    private long jwtExpirationMs;

    private Key getSigningKey() {
        return Keys.hmacShaKeyFor(jwtSecret.getBytes());
    }

    public String generateToken(UUID userId, String username, String role, String orgType,
                                 String activeNagarNigamId, String module, UUID sessionId) {
        Date expiry = new Date(System.currentTimeMillis() + jwtExpirationMs);

        return Jwts.builder()
                .setSubject(username)
                .claim("userId", userId.toString())
                .claim("role", role)
                .claim("orgType", orgType)
                .claim("activeNagarNigamId", activeNagarNigamId)
                .claim("module", module)
                .claim("sessionId", sessionId.toString())
                .setIssuedAt(new Date())
                .setExpiration(expiry)
                .signWith(getSigningKey(), SignatureAlgorithm.HS512)
                .compact();
    }

    public Claims parseClaims(String token) {
        return Jwts.parserBuilder()
                .setSigningKey(getSigningKey())
                .build()
                .parseClaimsJws(token)
                .getBody();
    }

    public boolean validateToken(String token) {
        try {
            parseClaims(token);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    public UUID getUserId(String token) {
        return UUID.fromString(parseClaims(token).get("userId", String.class));
    }

    public String getRole(String token) {
        return parseClaims(token).get("role", String.class);
    }

    public String getOrgType(String token) {
        return parseClaims(token).get("orgType", String.class);
    }

    public String getActiveNagarNigamId(String token) {
        return parseClaims(token).get("activeNagarNigamId", String.class);
    }

    public String getModule(String token) {
        return parseClaims(token).get("module", String.class);
    }

    public UUID getSessionId(String token) {
        return UUID.fromString(parseClaims(token).get("sessionId", String.class));
    }
}
