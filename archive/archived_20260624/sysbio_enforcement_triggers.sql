-- ============================================================
-- Custom OMOP CDM — Governance enforcement: delete-guard
-- Prevents deleting a governed record while any grant still references it.
-- This provides, via trigger, the integrity a foreign key's ON DELETE RESTRICT
-- would give automatically (the polymorphic GROUP_ACCESS table has no real FK
-- to the clinical tables). Grants are NEVER auto-removed; cascade is intentionally
-- not used, so an operator must consciously clear each grant first.
-- Replace @cdmDatabaseSchema with your schema name before running.
-- ============================================================

CREATE OR REPLACE FUNCTION @cdmDatabaseSchema.block_delete_with_grants()
RETURNS trigger AS $$
DECLARE
  fcid integer := TG_ARGV[0]::integer;     -- field_concept_id for this table
  pkcol text    := TG_ARGV[1];             -- primary-key column name
  rid  bigint   := (to_jsonb(OLD) ->> TG_ARGV[1])::bigint;
  n    integer;
BEGIN
  SELECT count(*) INTO n
  FROM @cdmDatabaseSchema.GROUP_ACCESS g
  WHERE g.field_concept_id = fcid AND g.record_id = rid;

  IF n > 0 THEN
    RAISE EXCEPTION
      'Cannot delete % %=%: % grant(s) still reference it. Remove the grants first.',
      TG_TABLE_NAME, pkcol, rid, n;
  END IF;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- One BEFORE DELETE guard per governed table (field_concept_id, pk column)
CREATE TRIGGER trg_guard_person            BEFORE DELETE ON @cdmDatabaseSchema.PERSON
  FOR EACH ROW EXECUTE FUNCTION @cdmDatabaseSchema.block_delete_with_grants(1147026,'person_id');
CREATE TRIGGER trg_guard_visit_occurrence  BEFORE DELETE ON @cdmDatabaseSchema.VISIT_OCCURRENCE
  FOR EACH ROW EXECUTE FUNCTION @cdmDatabaseSchema.block_delete_with_grants(1147070,'visit_occurrence_id');
CREATE TRIGGER trg_guard_condition         BEFORE DELETE ON @cdmDatabaseSchema.CONDITION_OCCURRENCE
  FOR EACH ROW EXECUTE FUNCTION @cdmDatabaseSchema.block_delete_with_grants(1147127,'condition_occurrence_id');
CREATE TRIGGER trg_guard_procedure         BEFORE DELETE ON @cdmDatabaseSchema.PROCEDURE_OCCURRENCE
  FOR EACH ROW EXECUTE FUNCTION @cdmDatabaseSchema.block_delete_with_grants(1147082,'procedure_occurrence_id');
CREATE TRIGGER trg_guard_measurement       BEFORE DELETE ON @cdmDatabaseSchema.MEASUREMENT
  FOR EACH ROW EXECUTE FUNCTION @cdmDatabaseSchema.block_delete_with_grants(1147138,'measurement_id');
CREATE TRIGGER trg_guard_observation       BEFORE DELETE ON @cdmDatabaseSchema.OBSERVATION
  FOR EACH ROW EXECUTE FUNCTION @cdmDatabaseSchema.block_delete_with_grants(1147165,'observation_id');
CREATE TRIGGER trg_guard_specimen          BEFORE DELETE ON @cdmDatabaseSchema.SPECIMEN
  FOR EACH ROW EXECUTE FUNCTION @cdmDatabaseSchema.block_delete_with_grants(1147049,'specimen_id');
CREATE TRIGGER trg_guard_observation_period BEFORE DELETE ON @cdmDatabaseSchema.OBSERVATION_PERIOD
  FOR EACH ROW EXECUTE FUNCTION @cdmDatabaseSchema.block_delete_with_grants(1147044,'observation_period_id');
