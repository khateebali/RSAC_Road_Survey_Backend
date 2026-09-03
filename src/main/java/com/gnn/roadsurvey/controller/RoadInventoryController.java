package com.gnn.roadsurvey.controller;

import com.gnn.roadsurvey.entity.RoadInventory;
import com.gnn.roadsurvey.repository.RoadInventoryRepository;
import com.gnn.roadsurvey.security.RequireAuth;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletRequest;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Every read is scoped by the session's activeNagarNigamId (set by
 * AuthInterceptor from the JWT — Section 5.1's session-scope rule), never a
 * client-supplied city, so a surveyor can't query another city's roads even
 * with a modified client.
 */
@RestController
@RequestMapping("/api/road-inventory")
public class RoadInventoryController {

    @Autowired
    private RoadInventoryRepository roadInventoryRepository;

    @GetMapping
    @RequireAuth
    public ResponseEntity<?> list(HttpServletRequest request,
                                   @RequestParam(required = false) String search) {
        String nagarNigamId = (String) request.getAttribute("activeNagarNigamId");
        List<RoadInventory> roads = roadInventoryRepository.findAllByNagarNigamId(nagarNigamId);

        if (search != null && !search.isBlank()) {
            String needle = search.toLowerCase();
            roads = roads.stream()
                    .filter(r -> (r.getRoadName() != null && r.getRoadName().toLowerCase().contains(needle))
                            || (r.getWardName() != null && r.getWardName().toLowerCase().contains(needle))
                            || (r.getRoadId() != null && r.getRoadId().toLowerCase().contains(needle)))
                    .collect(Collectors.toList());
        }

        return ResponseEntity.ok(roads.stream().map(this::summary).collect(Collectors.toList()));
    }

    @GetMapping("/{roadId}")
    @RequireAuth
    public ResponseEntity<?> get(HttpServletRequest request, @PathVariable String roadId) {
        String nagarNigamId = (String) request.getAttribute("activeNagarNigamId");
        return roadInventoryRepository.findById(roadId)
                .filter(r -> r.getNagarNigamId().equals(nagarNigamId))
                .map(r -> ResponseEntity.ok(detail(r)))
                .orElse(ResponseEntity.notFound().build());
    }

    private Map<String, Object> summary(RoadInventory r) {
        return Map.of(
                "roadId", r.getRoadId(),
                "roadName", r.getRoadName() == null ? "" : r.getRoadName(),
                "wardName", r.getWardName() == null ? "" : r.getWardName(),
                "zoneName", r.getZoneName() == null ? "" : r.getZoneName(),
                "category", r.getCategory() == null ? "" : r.getCategory()
        );
    }

    private Map<String, Object> detail(RoadInventory r) {
        return Map.ofEntries(
                Map.entry("roadId", r.getRoadId()),
                Map.entry("roadName", r.getRoadName() == null ? "" : r.getRoadName()),
                Map.entry("wardName", r.getWardName() == null ? "" : r.getWardName()),
                Map.entry("zoneName", r.getZoneName() == null ? "" : r.getZoneName()),
                Map.entry("category", r.getCategory() == null ? "" : r.getCategory()),
                Map.entry("ownership", r.getOwnership() == null ? "" : r.getOwnership()),
                Map.entry("lengthM", r.getLengthM() == null ? 0 : r.getLengthM())
        );
    }
}
