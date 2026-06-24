-- ============================================================
-- Custom OMOP CDM — Governance reconciliation (OPERATIONAL, run on demand)
-- DETECTION ONLY — this does NOT enforce anything. It surfaces integrity problems a
-- load may have introduced, which the structural guards (delete-guard, CHECKs) cannot
-- catch because GROUP_ACCESS.record_id is polymorphic (no FK). Run after a load:
--     SELECT * FROM @cdmDatabaseSchema.gov_reconciliation();
-- Empty result = clean. Not part of the schema DDL; safe to drop/recreate anytime.
--
-- Checks, per governed table:
--   dangling_grant         a grant whose record_id has no matching record
--   person_mismatch        a grant whose person_id <> the referenced record's real owner
--   orphan_no_person_grant a granted child record whose PERSON-row is NOT granted to the
--                          same group (or public) -> visible record, invisible person
-- Replace @cdmDatabaseSchema before running.
-- ============================================================

CREATE OR REPLACE FUNCTION @cdmDatabaseSchema.gov_reconciliation()
RETURNS TABLE(violation text, field_concept_id integer, tbl text,
              record_id bigint, grant_group varchar, person_id integer) AS $$
DECLARE
  -- table identifiers lowercase: unquoted DDL identifiers fold to lowercase in Postgres
  maps text[] := ARRAY[
    '1147026,person,person_id',
    '1147044,observation_period,observation_period_id',
    '1147070,visit_occurrence,visit_occurrence_id',
    '1147127,condition_occurrence,condition_occurrence_id',
    '1147082,procedure_occurrence,procedure_occurrence_id',
    '1147138,measurement,measurement_id',
    '1147165,observation,observation_id',
    '1147049,specimen,specimen_id'
  ];
  parts text[]; fcid integer; tname text; pk text; entry text;
BEGIN
  FOREACH entry IN ARRAY maps LOOP
    parts := string_to_array(entry, ',');
    fcid := parts[1]::integer; tname := parts[2]; pk := parts[3];

    -- A) dangling grant: record_id not present in the resolved table
    RETURN QUERY EXECUTE format(
      'SELECT ''dangling_grant''::text, g.field_concept_id, %L, g.record_id, g.grant_group, g.person_id
       FROM @cdmDatabaseSchema.GROUP_ACCESS g
       WHERE g.field_concept_id = %s
         AND NOT EXISTS (SELECT 1 FROM @cdmDatabaseSchema.%I t WHERE t.%I = g.record_id)',
      tname, fcid, tname, pk);

    -- B) person mismatch: grant.person_id <> the referenced record's owner
    RETURN QUERY EXECUTE format(
      'SELECT ''person_mismatch''::text, g.field_concept_id, %L, g.record_id, g.grant_group, g.person_id
       FROM @cdmDatabaseSchema.GROUP_ACCESS g
       JOIN @cdmDatabaseSchema.%I t ON t.%I = g.record_id
       WHERE g.field_concept_id = %s AND t.person_id <> g.person_id',
      tname, tname, pk, fcid);

    -- C) orphan: granted child record whose PERSON-row isn't granted to the same group/public
    IF fcid <> 1147026 THEN
      RETURN QUERY EXECUTE format(
        'SELECT ''orphan_no_person_grant''::text, g.field_concept_id, %L, g.record_id, g.grant_group, g.person_id
         FROM @cdmDatabaseSchema.GROUP_ACCESS g
         JOIN @cdmDatabaseSchema.%I t ON t.%I = g.record_id
         WHERE g.field_concept_id = %s
           AND NOT EXISTS (SELECT 1 FROM @cdmDatabaseSchema.GROUP_ACCESS gp
                           WHERE gp.field_concept_id = 1147026 AND gp.record_id = t.person_id
                             AND (gp.grant_group = g.grant_group OR gp.grant_group = ''public''))',
        tname, tname, pk, fcid);
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql;
