package com.gnn.roadsurvey.service;

import com.gnn.roadsurvey.dto.AuthResponse;
import com.gnn.roadsurvey.dto.LoginRequest;
import com.gnn.roadsurvey.entity.OrgType;
import com.gnn.roadsurvey.entity.SurveyModule;
import com.gnn.roadsurvey.entity.SurveySession;
import com.gnn.roadsurvey.entity.User;
import com.gnn.roadsurvey.repository.SurveySessionRepository;
import com.gnn.roadsurvey.repository.UserRepository;
import com.gnn.roadsurvey.security.JwtUtil;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Login flow implementing Section 5.3 of the plan: a NAGAR_NIGAM user's
 * session city comes from their fixed profile (no picker); an RSAC user
 * must supply requestedNagarNigamId, which becomes the session's scope for
 * its lifetime. Switching city = logging in again (a new session), never an
 * in-place mutation of an existing session's scope.
 */
@Service
public class AuthService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private SurveySessionRepository surveySessionRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtUtil jwtUtil;

    @Transactional
    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByUsername(request.getUsername())
                .orElseThrow(() -> new AuthException("Invalid username or password"));

        if (!user.isActive()) {
            throw new AuthException("Account is deactivated");
        }

        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new AuthException("Invalid username or password");
        }

        String activeNagarNigamId = resolveActiveCity(user, request.getRequestedNagarNigamId());
        String module = validateModule(request.getModule());

        SurveySession session = new SurveySession();
        session.setUserId(user.getUserId());
        session.setDeviceId(request.getDeviceId());
        session.setAppVersion(request.getAppVersion());
        session.setActiveNagarNigamId(activeNagarNigamId);
        session.setModule(module);
        session = surveySessionRepository.save(session);

        String token = jwtUtil.generateToken(
                user.getUserId(),
                user.getUsername(),
                user.getRole().name(),
                user.getOrgType().name(),
                activeNagarNigamId,
                module,
                session.getSessionId()
        );

        return new AuthResponse(token, user.getUserId().toString(), user.getName(),
                user.getRole().name(), user.getOrgType().name(), activeNagarNigamId, module);
    }

    private String validateModule(String module) {
        if (module == null) {
            throw new AuthException("A survey module must be selected at login");
        }
        try {
            return SurveyModule.valueOf(module).name();
        } catch (IllegalArgumentException e) {
            throw new AuthException("Unknown survey module: " + module);
        }
    }

    private String resolveActiveCity(User user, String requestedNagarNigamId) {
        if (user.getOrgType() == OrgType.NAGAR_NIGAM) {
            // Fixed on the profile — a requested city, if sent, is silently ignored,
            // never honored, so a modified client can't ask its way into another city.
            return user.getNagarNigamId();
        }

        // RSAC: must actively choose a city each login.
        if (requestedNagarNigamId == null || requestedNagarNigamId.isBlank()) {
            throw new AuthException("RSAC accounts must select a city to work in at login");
        }
        return requestedNagarNigamId;
    }
}
