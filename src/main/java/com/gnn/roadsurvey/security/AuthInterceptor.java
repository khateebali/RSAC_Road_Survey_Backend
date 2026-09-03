package com.gnn.roadsurvey.security;

import com.gnn.roadsurvey.entity.SurveySession;
import com.gnn.roadsurvey.repository.SurveySessionRepository;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.web.method.HandlerMethod;
import org.springframework.web.servlet.HandlerInterceptor;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.Arrays;
import java.util.Optional;
import java.util.UUID;

/**
 * Same interceptor pattern as LKO_NN's AuthInterceptor, extended with:
 *  - role-scoped access via @RequireAuth(roles = ...)
 *  - session-idle enforcement against survey_sessions.last_heartbeat_at
 *    (Section 6.2's 30-minute heartbeat threshold), not just token
 *    signature/expiry validity
 *  - request attributes for userId/role/orgType/activeNagarNigamId so
 *    controllers scope every query from the token, never a client parameter
 */
@Component
public class AuthInterceptor implements HandlerInterceptor {

    private static final long HEARTBEAT_IDLE_LIMIT_MINUTES = 30;

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private SurveySessionRepository surveySessionRepository;

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler)
            throws Exception {

        if (!(handler instanceof HandlerMethod handlerMethod)) {
            return true;
        }

        RequireAuth requireAuth = handlerMethod.getMethod().getAnnotation(RequireAuth.class);
        if (requireAuth == null) {
            return true;
        }

        String token = extractToken(request);
        if (token == null || !jwtUtil.validateToken(token)) {
            return unauthorized(response, "Missing or invalid token");
        }

        UUID sessionId = jwtUtil.getSessionId(token);
        Optional<SurveySession> sessionOpt = surveySessionRepository.findById(sessionId);
        if (sessionOpt.isEmpty() || sessionOpt.get().getLogoutAt() != null) {
            return unauthorized(response, "Session ended");
        }

        SurveySession session = sessionOpt.get();
        long idleMinutes = ChronoUnit.MINUTES.between(session.getLastHeartbeatAt(), LocalDateTime.now());
        if (idleMinutes > HEARTBEAT_IDLE_LIMIT_MINUTES) {
            return unauthorized(response, "Session expired due to inactivity");
        }

        String role = jwtUtil.getRole(token);
        if (requireAuth.roles().length > 0 && Arrays.stream(requireAuth.roles()).noneMatch(r -> r.equals(role))) {
            response.setStatus(HttpServletResponse.SC_FORBIDDEN);
            response.setContentType("application/json");
            response.getWriter().write("{\"status\":false,\"message\":\"Insufficient role\"}");
            return false;
        }

        request.setAttribute("userId", jwtUtil.getUserId(token));
        request.setAttribute("role", role);
        request.setAttribute("orgType", jwtUtil.getOrgType(token));
        request.setAttribute("activeNagarNigamId", jwtUtil.getActiveNagarNigamId(token));
        request.setAttribute("sessionId", sessionId);

        return true;
    }

    private String extractToken(HttpServletRequest request) {
        if (request.getCookies() != null) {
            for (var cookie : request.getCookies()) {
                if ("token".equals(cookie.getName())) {
                    return cookie.getValue();
                }
            }
        }
        String header = request.getHeader("Authorization");
        if (header != null && header.startsWith("Bearer ")) {
            return header.substring(7);
        }
        return null;
    }

    private boolean unauthorized(HttpServletResponse response, String message) throws Exception {
        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        response.setContentType("application/json");
        response.getWriter().write("{\"status\":false,\"message\":\"" + message + "\"}");
        return false;
    }
}
