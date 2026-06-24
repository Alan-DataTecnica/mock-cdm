-- ============================================================
-- Custom OMOP CDM — Read-side access enforcement: OPTION A — Row-Level Security
-- A governed record is visible only if GROUP_ACCESS grants it to one of the
-- connection's groups, or the record is 'public'. Enforced by the database on
-- every SELECT, transparently (users keep querying the real table names).
--
-- CONTRACT WITH THE PLATFORM / AUTH TEAM (the only external dependency):
--   Before querying, the connection sets its groups as a comma-separated string:
--       SET app.current_groups = 'studyA,studyB';
--   Unset  -> treated as empty -> only 'public' rows are visible (fail-closed).
--   Defining WHERE these groups come from (login, directory, etc.) is the auth
--   team's job; this file only consumes the variable.
--
-- INTERCHANGEABLE with sysbio_readside_views.sql — pick ONE mechanism.
-- Notes: table OWNER bypasses RLS unless FORCE is used; keep the ETL/loader role
--   as owner (or BYPASSRLS) so loads are unfiltered, and have analysts connect as
--   a non-owner role. Replace @cdmDatabaseSchema before running.
-- ============================================================

ALTER TABLE @cdmDatabaseSchema.PERSON ENABLE ROW LEVEL SECURITY;
CREATE POLICY rls_person ON @cdmDatabaseSchema.PERSON FOR SELECT USING (
  EXISTS (SELECT 1 FROM @cdmDatabaseSchema.GROUP_ACCESS g
          WHERE g.field_concept_id = 1147026 AND g.record_id = @cdmDatabaseSchema.PERSON.person_id
            AND (g.grant_group = ANY (string_to_array(current_setting('app.current_groups', true), ','))
                 OR g.grant_group = 'public')));

ALTER TABLE @cdmDatabaseSchema.VISIT_OCCURRENCE ENABLE ROW LEVEL SECURITY;
CREATE POLICY rls_visit_occurrence ON @cdmDatabaseSchema.VISIT_OCCURRENCE FOR SELECT USING (
  EXISTS (SELECT 1 FROM @cdmDatabaseSchema.GROUP_ACCESS g
          WHERE g.field_concept_id = 1147070 AND g.record_id = @cdmDatabaseSchema.VISIT_OCCURRENCE.visit_occurrence_id
            AND (g.grant_group = ANY (string_to_array(current_setting('app.current_groups', true), ','))
                 OR g.grant_group = 'public')));

ALTER TABLE @cdmDatabaseSchema.CONDITION_OCCURRENCE ENABLE ROW LEVEL SECURITY;
CREATE POLICY rls_condition_occurrence ON @cdmDatabaseSchema.CONDITION_OCCURRENCE FOR SELECT USING (
  EXISTS (SELECT 1 FROM @cdmDatabaseSchema.GROUP_ACCESS g
          WHERE g.field_concept_id = 1147127 AND g.record_id = @cdmDatabaseSchema.CONDITION_OCCURRENCE.condition_occurrence_id
            AND (g.grant_group = ANY (string_to_array(current_setting('app.current_groups', true), ','))
                 OR g.grant_group = 'public')));

ALTER TABLE @cdmDatabaseSchema.PROCEDURE_OCCURRENCE ENABLE ROW LEVEL SECURITY;
CREATE POLICY rls_procedure_occurrence ON @cdmDatabaseSchema.PROCEDURE_OCCURRENCE FOR SELECT USING (
  EXISTS (SELECT 1 FROM @cdmDatabaseSchema.GROUP_ACCESS g
          WHERE g.field_concept_id = 1147082 AND g.record_id = @cdmDatabaseSchema.PROCEDURE_OCCURRENCE.procedure_occurrence_id
            AND (g.grant_group = ANY (string_to_array(current_setting('app.current_groups', true), ','))
                 OR g.grant_group = 'public')));

ALTER TABLE @cdmDatabaseSchema.MEASUREMENT ENABLE ROW LEVEL SECURITY;
CREATE POLICY rls_measurement ON @cdmDatabaseSchema.MEASUREMENT FOR SELECT USING (
  EXISTS (SELECT 1 FROM @cdmDatabaseSchema.GROUP_ACCESS g
          WHERE g.field_concept_id = 1147138 AND g.record_id = @cdmDatabaseSchema.MEASUREMENT.measurement_id
            AND (g.grant_group = ANY (string_to_array(current_setting('app.current_groups', true), ','))
                 OR g.grant_group = 'public')));

ALTER TABLE @cdmDatabaseSchema.OBSERVATION ENABLE ROW LEVEL SECURITY;
CREATE POLICY rls_observation ON @cdmDatabaseSchema.OBSERVATION FOR SELECT USING (
  EXISTS (SELECT 1 FROM @cdmDatabaseSchema.GROUP_ACCESS g
          WHERE g.field_concept_id = 1147165 AND g.record_id = @cdmDatabaseSchema.OBSERVATION.observation_id
            AND (g.grant_group = ANY (string_to_array(current_setting('app.current_groups', true), ','))
                 OR g.grant_group = 'public')));

ALTER TABLE @cdmDatabaseSchema.SPECIMEN ENABLE ROW LEVEL SECURITY;
CREATE POLICY rls_specimen ON @cdmDatabaseSchema.SPECIMEN FOR SELECT USING (
  EXISTS (SELECT 1 FROM @cdmDatabaseSchema.GROUP_ACCESS g
          WHERE g.field_concept_id = 1147049 AND g.record_id = @cdmDatabaseSchema.SPECIMEN.specimen_id
            AND (g.grant_group = ANY (string_to_array(current_setting('app.current_groups', true), ','))
                 OR g.grant_group = 'public')));

ALTER TABLE @cdmDatabaseSchema.OBSERVATION_PERIOD ENABLE ROW LEVEL SECURITY;
CREATE POLICY rls_observation_period ON @cdmDatabaseSchema.OBSERVATION_PERIOD FOR SELECT USING (
  EXISTS (SELECT 1 FROM @cdmDatabaseSchema.GROUP_ACCESS g
          WHERE g.field_concept_id = 1147044 AND g.record_id = @cdmDatabaseSchema.OBSERVATION_PERIOD.observation_period_id
            AND (g.grant_group = ANY (string_to_array(current_setting('app.current_groups', true), ','))
                 OR g.grant_group = 'public')));
