package com.gnn.roadsurvey.repository;

import com.gnn.roadsurvey.entity.SurveySession;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface SurveySessionRepository extends JpaRepository<SurveySession, UUID> {
}
