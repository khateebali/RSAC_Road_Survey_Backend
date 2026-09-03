package com.gnn.roadsurvey.controller;

import com.gnn.roadsurvey.dto.AuthResponse;
import com.gnn.roadsurvey.dto.LoginRequest;
import com.gnn.roadsurvey.entity.SurveySession;
import com.gnn.roadsurvey.repository.SurveySessionRepository;
import com.gnn.roadsurvey.security.RequireAuth;
import com.gnn.roadsurvey.service.AuthException;
import com.gnn.roadsurvey.service.AuthService;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletRequest;
import javax.validation.Valid;
import java.time.LocalDateTime;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    @Autowired
    private AuthService authService;

    @Autowired
    private SurveySessionRepository surveySessionRepository;

    @PostMapping("/login")
    public ResponseEntity<?> login(@Valid @RequestBody LoginRequest request) {
        try {
            AuthResponse response = authService.login(request);
            return ResponseEntity.ok(response);
        } catch (AuthException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("status", false, "message", e.getMessage()));
        }
    }

    // Section 6.2 — heartbeat: every form submission also counts as an implicit
    // heartbeat, but the app pings this directly every few minutes while active.
    @PostMapping("/session/heartbeat")
    @RequireAuth
    public ResponseEntity<?> heartbeat(HttpServletRequest request) {
        UUID sessionId = (UUID) request.getAttribute("sessionId");
        SurveySession session = surveySessionRepository.findById(sessionId)
                .orElseThrow(() -> new AuthException("Session not found"));
        session.setLastHeartbeatAt(LocalDateTime.now());
        surveySessionRepository.save(session);
        return ResponseEntity.ok(Map.of("status", true));
    }

    @PostMapping("/logout")
    @RequireAuth
    public ResponseEntity<?> logout(HttpServletRequest request) {
        UUID sessionId = (UUID) request.getAttribute("sessionId");
        SurveySession session = surveySessionRepository.findById(sessionId)
                .orElseThrow(() -> new AuthException("Session not found"));
        session.setLogoutAt(LocalDateTime.now());
        surveySessionRepository.save(session);
        return ResponseEntity.ok(Map.of("status", true));
    }
}
