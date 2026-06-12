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

Enforcement is applied at the database layer and reads `group_access` to decide which rows a user may see. Here are two possible mechanisms. The implementing team chooses based on best fit for the platform:

- Row-level security: a rule attached to a table that the database applies automatically to every query.
- Filtered views: views that contain the access filter, which users query instead of the base tables.

Each table is filtered independently. A foreign key value (for example, a `visit_occurrence_id` stored on a measurement) remains visible as a value, but the referenced record's contents are governed by that record's own grant. References do not cascade visibility.

## Record Lifecycle, Leak Prevention, and Deletion Protection

A record that arrives at load time without a group-access label (a grant) is rejected. No record is ever stored without defined access.

**A record can never be deleted while any grant still references it.** The database enforces this with a `BEFORE DELETE` guard that raises an error if a matching `group_access` row exists; the guard blocks the deletion and removes nothing.

To delete a record, an operator must first explicitly remove each of its grants — which forces them to see exactly which groups are attached and to consciously revoke each one, fully aware that those groups lose access. Only once zero grants remain will the database permit the record to be deleted.

Grants are never removed automatically as a side effect of deleting a record.

Cascade-style cleanup is specifically advised against: it would silently strip every attached group's access, hiding the cross-group consequence of a deletion from the person performing it.

**The whole point is that this consequence must be visible and deliberate.**

Together these rules make dangling grants impossible. The database will not permit the deletion that would create one. This makes every loss of group access an explicit, acknowledged act rather than a side effect.

This protection is enforced by a trigger (or equivalently by revoking direct `DELETE` rights and routing deletions through a procedure that performs the same check) because the polymorphic grant table cannot carry a database-enforced foreign key.

It provides something similar to what a foreign key's `ON DELETE RESTRICT` would provide automatically; only the implementation differs.

## Revoking vs Deleting

These are distinct operations:

- **Revoke** removes a grant row (an access change). A record shared with other groups keeps those groups' grants and remains visible to them. When a record's last grant is removed, the default-deny rule hides it.
- **Delete** removes the record itself (a data change). This is separate and deliberate, and is the path used when the last grant is gone or a curator removes data.

Because `person_id` is on the grant table, a whole person can be revoked from a group in a single statement (`DELETE ... WHERE person_id = :p AND grant_group = :g`), and any person-scoped adjustment is one operation rather than a scan across every clinical table. `person_id` is treated as immutable because identity is resolved before load.

## Implementation Notes

The data model and lifecycle rules are specified here; the enforcement mechanism, indexing, and performance tuning are the implementing team's decisions, based on the platform. To implement enforcement, that team needs three things handed over explicitly:

1. The visibility rule, stated plainly: a user may see a record if and only if `group_access` contains a row matching that record with a `grant_group` the user belongs to, or `grant_group = public`.
2. A user-to-group mapping — how the system determines which groups the connecting user belongs to. This is required by any enforcement mechanism and is not yet defined.
3. The field-concept-to-table mapping (the project's `polymorphic_fk_map.json`), so the enforcement query can resolve a `record_id` to its table and join correctly.

## Scope of Governance

`group_access` governs the person-scoped clinical records. Two custom tables sit outside it, by design:

- **ASSAY** is ungoverned. An assay row is non-identifying on its own — the only person↔assay linkage runs through the clinical records (a measurement's polymorphic event link or FACT_RELATIONSHIP), which are governed. Without access to a person's clinical records, there is no path to associate that person with any assay — or to tell whether they appear in one at all. Open assay metadata therefore leaks nothing.
- **FILE_ASSET** is ungoverned. The row is only a pointer to a file hosted by the AMP; obtaining the file requires a separate application and use agreement. Seeing the pointer does not grant the file, so there is nothing to protect at the row level.
