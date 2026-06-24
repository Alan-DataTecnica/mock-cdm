# Custom OMOP CDM — Governance Control Set (sysbio, 2026-06-12)

Record-level access governance for a customized OMOP CDM v5.4 subset (clinical + vocabulary
tables, plus custom `ASSAY` / `FILE_ASSET`, plus the `GROUP_ACCESS` governance table).
All SQL uses the OHDSI `@cdmDatabaseSchema` placeholder; the read-side views file also uses
`@cdmResultSchema`. Substitute before running.

## Design & reference docs
- **governanceREADME.md** — the record-level access governance design (model, grant table, lifecycle, enforcement, scope). Start here.
- **Key_Implementations.md** — how every key is wired: native foreign keys, the two polymorphic patterns (field-level vs table-level), and the concept-ID conventions behind them.
- **omop_cdm_conventions-w-sysbio.xlsx** — field-level data dictionary, one sheet per table + combined `Data_Dictionary` (User Guide / ETL Convention columns; table descriptions from OHDSI cdm54).
- **sysbio-dbml-20260611.dbml** / **sysbio-cdm-erd-20260611.png** — ERD source + image. ⚠️ **STALE** — predate PERSON full-shape-with-sentinels and OBSERVATION_PERIOD governance; regenerate from the DBML (paste into dbdiagram.io) before relying on the picture.

## SQL artifacts — schema & enforcement

**Prerequisite — load the OMOP Standardized Vocabularies first.** The schema creates the
vocabulary tables (CONCEPT, VOCABULARY, DOMAIN, …) **empty**. Download the OMOP vocabularies
from OHDSI Athena (https://athena.ohdsi.org) and load them before loading any data — the
governance layer depends on standard concepts from that download: the `'Field'`/`'Table'`
resolver concepts in the ~`1147xxx` range and concept_id `0` ("No matching concept").

Run in this order:
1. **sysbioDDL.sql** — schema: tables, PKs/FKs, indexes, and the PERSON sentinel `CHECK` constraints (gender/race/ethnicity pinned to `0`).
2. **sysbio_enforcement_triggers.sql** — `BEFORE DELETE` guard on the 8 governed tables (a record can't be deleted while a grant references it).
3. **Read-side filter — pick ONE** (interchangeable; both tested):
   - **sysbio_readside_rls.sql** — Postgres Row-Level Security (transparent; analysts query real table names).
   - **sysbio_readside_views.sql** — filtered views in `@cdmResultSchema` (only protective if direct base-table access is revoked).
   - Both read the session variable `app.current_groups` (comma-separated groups; unset → `public`-only, fail-closed) — supplied by the auth layer.

## SQL artifacts — operational
- **sysbio_governance_reconciliation.sql** — on-demand detection (NOT enforcement). `SELECT * FROM <schema>.gov_reconciliation();` returns integrity gaps the structural guards can't catch: dangling grants (record absent), person mismatches, and orphaned records (visible record whose PERSON-row isn't granted to the same group). Empty result = clean. Run after each load.

## Governed table set
PERSON, OBSERVATION_PERIOD, VISIT_OCCURRENCE, CONDITION_OCCURRENCE, PROCEDURE_OCCURRENCE,
MEASUREMENT, OBSERVATION, SPECIMEN. ASSAY and FILE_ASSET are ungoverned by design (see governanceREADME).

## Open items (not yet resolved)
- Placeholder **value** for `PERSON.year_of_birth` (a conscious deviation from THEMIS's "no placeholder").
- CDM_SOURCE-as-group **FK implementation** (promote `cdm_source_abbreviation` to unique key; add the `'public'` row; group codes must fit `varchar(25)`).
- **User→group mapping** — external (auth team), via `app.current_groups`.
- Regenerate the **ERD/DBML** to match current schema.
