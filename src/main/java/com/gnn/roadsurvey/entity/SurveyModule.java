package com.gnn.roadsurvey.entity;

/**
 * Chosen at login, fixed for the session's lifetime — lets two surveyors work the
 * same road at the same time without collision, since each module writes to a
 * distinct set of tables.
 */
public enum SurveyModule {
    ROAD_DIRECTORY_UPDATE,   // old app's road-level record editing
    DRAIN_UPDATE,            // old app's drainage editing
    ROAD_INVENTORY_SURVEY    // the new tender's 12-layer detailed survey (Section 2)
}
