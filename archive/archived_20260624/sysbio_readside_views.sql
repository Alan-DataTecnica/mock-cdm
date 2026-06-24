-- ============================================================
-- Custom OMOP CDM — Read-side access enforcement: OPTION B — Filtered Views
-- One view per governed table in a separate schema, each carrying the same
-- visibility filter. Users query the view schema instead of the base tables.
--
-- CONTRACT WITH THE PLATFORM / AUTH TEAM (the only external dependency):
--   Before querying, the connection sets its groups as a comma-separated string:
--       SET app.current_groups = 'studyA,studyB';
--   Unset  -> treated as empty -> only 'public' rows are visible (fail-closed).
--   Defining WHERE these groups come from is the auth team's job; this file only
--   consumes the variable.
--
-- INTERCHANGEABLE with sysbio_readside_rls.sql — pick ONE mechanism.
-- To make it binding, the platform must: REVOKE SELECT on the @cdmDatabaseSchema
--   base tables from analyst roles, and GRANT SELECT on @cdmResultSchema views.
--   (Unlike RLS, a view is only protective if direct base-table access is removed.)
-- Replace @cdmDatabaseSchema and @cdmResultSchema before running.
-- ============================================================

CREATE SCHEMA IF NOT EXISTS @cdmResultSchema;

CREATE VIEW @cdmResultSchema.PERSON AS
  SELECT t.* FROM @cdmDatabaseSchema.PERSON t
  WHERE EXISTS (SELECT 1 FROM @cdmDatabaseSchema.GROUP_ACCESS g
                WHERE g.field_concept_id = 1147026 AND g.record_id = t.person_id
                  AND (g.grant_group = ANY (string_to_array(current_setting('app.current_groups', true), ','))
                       OR g.grant_group = 'public'));

CREATE VIEW @cdmResultSchema.VISIT_OCCURRENCE AS
  SELECT t.* FROM @cdmDatabaseSchema.VISIT_OCCURRENCE t
  WHERE EXISTS (SELECT 1 FROM @cdmDatabaseSchema.GROUP_ACCESS g
                WHERE g.field_concept_id = 1147070 AND g.record_id = t.visit_occurrence_id
                  AND (g.grant_group = ANY (string_to_array(current_setting('app.current_groups', true), ','))
                       OR g.grant_group = 'public'));

CREATE VIEW @cdmResultSchema.CONDITION_OCCURRENCE AS
  SELECT t.* FROM @cdmDatabaseSchema.CONDITION_OCCURRENCE t
  WHERE EXISTS (SELECT 1 FROM @cdmDatabaseSchema.GROUP_ACCESS g
                WHERE g.field_concept_id = 1147127 AND g.record_id = t.condition_occurrence_id
                  AND (g.grant_group = ANY (string_to_array(current_setting('app.current_groups', true), ','))
                       OR g.grant_group = 'public'));

CREATE VIEW @cdmResultSchema.PROCEDURE_OCCURRENCE AS
  SELECT t.* FROM @cdmDatabaseSchema.PROCEDURE_OCCURRENCE t
  WHERE EXISTS (SELECT 1 FROM @cdmDatabaseSchema.GROUP_ACCESS g
                WHERE g.field_concept_id = 1147082 AND g.record_id = t.procedure_occurrence_id
                  AND (g.grant_group = ANY (string_to_array(current_setting('app.current_groups', true), ','))
                       OR g.grant_group = 'public'));

CREATE VIEW @cdmResultSchema.MEASUREMENT AS
  SELECT t.* FROM @cdmDatabaseSchema.MEASUREMENT t
  WHERE EXISTS (SELECT 1 FROM @cdmDatabaseSchema.GROUP_ACCESS g
                WHERE g.field_concept_id = 1147138 AND g.record_id = t.measurement_id
                  AND (g.grant_group = ANY (string_to_array(current_setting('app.current_groups', true), ','))
                       OR g.grant_group = 'public'));

CREATE VIEW @cdmResultSchema.OBSERVATION AS
  SELECT t.* FROM @cdmDatabaseSchema.OBSERVATION t
  WHERE EXISTS (SELECT 1 FROM @cdmDatabaseSchema.GROUP_ACCESS g
                WHERE g.field_concept_id = 1147165 AND g.record_id = t.observation_id
                  AND (g.grant_group = ANY (string_to_array(current_setting('app.current_groups', true), ','))
                       OR g.grant_group = 'public'));

CREATE VIEW @cdmResultSchema.SPECIMEN AS
  SELECT t.* FROM @cdmDatabaseSchema.SPECIMEN t
  WHERE EXISTS (SELECT 1 FROM @cdmDatabaseSchema.GROUP_ACCESS g
                WHERE g.field_concept_id = 1147049 AND g.record_id = t.specimen_id
                  AND (g.grant_group = ANY (string_to_array(current_setting('app.current_groups', true), ','))
                       OR g.grant_group = 'public'));

CREATE VIEW @cdmResultSchema.OBSERVATION_PERIOD AS
  SELECT t.* FROM @cdmDatabaseSchema.OBSERVATION_PERIOD t
  WHERE EXISTS (SELECT 1 FROM @cdmDatabaseSchema.GROUP_ACCESS g
                WHERE g.field_concept_id = 1147044 AND g.record_id = t.observation_period_id
                  AND (g.grant_group = ANY (string_to_array(current_setting('app.current_groups', true), ','))
                       OR g.grant_group = 'public'));
