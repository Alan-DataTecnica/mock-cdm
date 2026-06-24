# Record-Level Access Governance for a Customized OMOP CDM

## Purpose

This describes a record-level access-control approach for an OMOP CDM instance that holds data from many sources, where the same participant may appear in more than one source and different users are permitted to see different subsets of records. It covers how records are labeled for access, how access is granted and revoked, and what the implementing team needs to enforce it. It does not prescribe the enforcement mechanism; that is left to the platform team.

## Overview

Access control is held in a single table (`group_access`) rather than in columns added to the clinical tables. Each grant ties a record to a group that may see it. A record can be granted to multiple groups by having multiple grant rows. Visibility is applied at query time by the database, not by the data model itself.

The approach is intended to keep the core OMOP tables unchanged, which preserves compatibility with OHDSI tooling that expects the canonical schema. It does not modify table structures or add access columns to clinical tables.

## Model

Governance lives in one junction table, `group_access`, alongside the standard CDM and the project's custom tables (`assay`, `file_asset`). No access columns are added to any tables. The grant table uses the OMOP polymorphic-reference pattern (a field concept identifying which table a record id belongs to), which is the same mechanism the CDM already uses for event references and the FACT_RELATIONSHIP table.

## How a Grant Works

A grant is identified by three columns:

- `field_concept_id` — identifies which table's id-field the record id refers to.
  - There are unique concept_ids that represent each individual field.
- `record_id` — the id of the granted record (polymorphic; resolved by `field_concept_id`).
- `grant_group` — the group permitted to see that record.

A `person_id` column is part of the grant table; it is what makes person-level operations possible without scanning every clinical table (see [Revoking vs Deleting](#revoking-vs-deleting)).

The composite of these three is the natural key. Grants reference record ids, not record values. A record visible to several groups has one grant row per group.

## Default-Deny and Public Data

Records are not loaded without at least one grant defined.

A record with no matching grant is not returned to a user. This fails closed: a record can only be hidden by the absence of a grant, never exposed by it.

Public data is represented with a dedicated `grant_group` value (e.g., `public`). A public record has one grant row carrying that value and is visible to all groups. This satisfies the default-deny rule (the record has a grant) without writing a separate grant per group.

## Enforcement

Enforcement is applied at the database layer and reads `group_access` to decide which rows a user may see. Both mechanisms below are now **built and tested**; the implementing team picks ONE based on platform fit:

- Row-level security — `sysbio_readside_rls.sql` (one policy per governed table; the database applies it automatically to every query).
- Filtered views — `sysbio_readside_views.sql` (views carrying the access filter, in a separate schema, which users query instead of the base tables).

Both express the same rule and depend on **one input from the platform/auth team**: a session variable `app.current_groups` (comma-separated list of the connecting user's groups). Unset → only `public` rows are visible (**fail-closed**). Defining where that membership comes from is the auth layer's responsibility, outside this design.

Each table is filtered independently. A foreign key value (for example, a `visit_occurrence_id` stored on a measurement) remains visible as a value, but the referenced record's contents are governed by that record's own grant. References do not cascade visibility.

## Record Lifecycle, Leak Prevention, and Deletion Protection

The ETL must not load a record without a grant. Note this is an **ETL responsibility, not a schema constraint**: the database does not itself reject an ungranted record — but such a record is invisible to everyone (default-deny / fail-closed) and is surfaced by the reconciliation check (`sysbio_governance_reconciliation.sql`). So the failure mode of a missing grant is *under*-exposure (a record nobody sees), never a leak.

**A record can never be deleted while any grant still references it.** The database enforces this with a `BEFORE DELETE` guard that raises an error if a matching `group_access` row exists; the guard blocks the deletion and removes nothing.

To delete a record, an operator must first explicitly remove each of its grants — which forces them to see exactly which groups are attached and to consciously revoke each one, fully aware that those groups lose access. Only once zero grants remain will the database permit the record to be deleted.

Grants are never removed automatically as a side effect of deleting a record.

Cascade-style cleanup is specifically advised against: it would silently strip every attached group's access, hiding the cross-group consequence of a deletion from the person performing it.

**The whole point is that this consequence must be visible and deliberate.**

Together these rules make dangling grants impossible. The database will not permit the deletion that would create one. This makes every loss of group access an explicit, acknowledged act rather than a side effect.

This protection is enforced by a trigger (or equivalently by revoking direct `DELETE` rights and routing deletions through a procedure that performs the same check) because the polymorphic grant table cannot carry a database-enforced foreign key.

It provides something similar to what a foreign key's `ON DELETE RESTRICT` would provide automatically; only the implementation differs.

**PERSON is additionally protected by a real foreign key.** Because `group_access.person_id` is a genuine FK to `PERSON`, the database already refuses to delete a person while *any* grant row carries their `person_id` — independent of the delete-guard trigger, and regardless of that grant's `field_concept_id`. So PERSON deletion is covered twice: natively by the FK (any grant for that person) and by the trigger (person-typed grants specifically). The other governed tables have no such FK and rely on the trigger alone.

## Revoking vs Deleting

These are distinct operations:

- **Revoke** removes a grant row (an access change). A record shared with other groups keeps those groups' grants and remains visible to them. When a record's last grant is removed, the default-deny rule hides it.
- **Delete** removes the record itself (a data change). This is separate and deliberate, and is the path used when the last grant is gone or a curator removes data.

Because `person_id` is on the grant table, a whole person can be revoked from a group in a single statement (`DELETE ... WHERE person_id = :p AND grant_group = :g`), and any person-scoped adjustment is one operation rather than a scan across every clinical table. `person_id` is treated as immutable because identity is resolved before load.

## Implementation Notes

The data model and lifecycle rules are specified here; indexing and performance tuning remain the implementing team's decisions. Status of the three things enforcement needs:

1. **The visibility rule — DONE.** "A user may see a record iff `group_access` has a matching row with a `grant_group` the user belongs to, or `grant_group = 'public'`." Implemented in both read-side files.
2. **User-to-group mapping — EXTERNAL (auth team).** Still not defined here, by design — it is supplied to the enforcement as the `app.current_groups` session variable. This is the one remaining external dependency.
3. **Field-concept-to-table resolution — NATIVE.** No custom map needed: the `field_concept_id` values are OMOP `'Field'`-class concepts whose `concept_name` is literally `table.column` (e.g. `1147026` → `person.person_id`). The project's `polymorphic_fk_map.json` is just a convenience copy of that.

Detection of integrity gaps the structural guards cannot catch (dangling grants, person mismatches, orphaned records) is provided as an on-demand operational query — `sysbio_governance_reconciliation.sql`.

## Scope of Governance

`group_access` governs the **eight** person-scoped tables: PERSON, OBSERVATION_PERIOD, VISIT_OCCURRENCE, CONDITION_OCCURRENCE, PROCEDURE_OCCURRENCE, MEASUREMENT, OBSERVATION, SPECIMEN. Each has a delete-guard and a read-side filter keyed on its OMOP field-concept code (e.g. PERSON `1147026`, OBSERVATION_PERIOD `1147044`).

Two supporting points on the governed set:

- **`grant_group` values are validated against `CDM_SOURCE`** (one row per ETL delivery/source; FK `group_access.grant_group → cdm_source(cdm_source_abbreviation)`, which is promoted to a unique key). `'public'` has its own CDM_SOURCE row. This is what stops a grant naming a non-existent group.
- **PERSON carries no real demographics.** `gender/race/ethnicity_concept_id` are pinned to `0` by `CHECK` constraints, and `year_of_birth` holds a placeholder; the real demographic values live as governed OBSERVATION records (grantable per access) and are populated into PERSON only at export, when the consuming group is permitted. PERSON is therefore just the roster of who exists.

Two custom tables sit outside governance, by design:

- **ASSAY** is ungoverned. An assay row is non-identifying on its own — the only person↔assay linkage runs through the clinical records (a measurement's polymorphic event link or FACT_RELATIONSHIP), which are governed. Without access to a person's clinical records, there is no path to associate that person with any assay — or to tell whether they appear in one at all. Open assay metadata therefore leaks nothing.
- **FILE_ASSET** is ungoverned. The row is only a pointer to a file hosted by the AMP; obtaining the file requires a separate application and use agreement. Seeing the pointer does not grant the file, so there is nothing to protect at the row level.
