package com.gnn.roadsurvey.repository;

import com.gnn.roadsurvey.entity.RoadInventory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface RoadInventoryRepository extends JpaRepository<RoadInventory, String> {

    // Every read is scoped by nagarNigamId (the session's activeNagarNigamId,
    // never a client-supplied value) — Section 5.1's session-scope rule.
    @Query("SELECT r FROM RoadInventory r WHERE r.nagarNigamId = :nagarNigamId")
    List<RoadInventory> findAllByNagarNigamId(@Param("nagarNigamId") String nagarNigamId);
}
