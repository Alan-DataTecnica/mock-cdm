# OMOP CDM v5.4 — Key Implementations (Custom Set)

How every key is wired in our table set: native foreign keys, the two polymorphic
patterns (field-level vs table-level), and the concept-ID conventions behind them.

## Table set in scope

PERSON, OBSERVATION_PERIOD, VISIT_OCCURRENCE, CONDITION_OCCURRENCE,
PROCEDURE_OCCURRENCE, MEASUREMENT, OBSERVATION, SPECIMEN, FACT_RELATIONSHIP,
CDM_SOURCE, and the vocabulary tables (CONCEPT, etc.); custom: ASSAY, FILE_ASSET,
GROUP_ACCESS.

Dropped tables (VISIT_DETAIL, PROVIDER, CARE_SITE, LOCATION, NOTE, EPISODE, the era
tables, etc.) do not appear here — including as FK targets. Their columns may still
exist on clinical tables.

---

## 1. Native foreign keys

Standard, static FKs between entity tables. `*_concept_id → CONCEPT` links are omitted
here (every concept field references CONCEPT); this lists entity keys only.

| Source table | Source column | Target table | Target column |
|---|---|---|---|
| OBSERVATION_PERIOD | person_id | PERSON | person_id |
| VISIT_OCCURRENCE | person_id | PERSON | person_id |
| CONDITION_OCCURRENCE | person_id | PERSON | person_id |
| CONDITION_OCCURRENCE | visit_occurrence_id | VISIT_OCCURRENCE | visit_occurrence_id |
| PROCEDURE_OCCURRENCE | person_id | PERSON | person_id |
| PROCEDURE_OCCURRENCE | visit_occurrence_id | VISIT_OCCURRENCE | visit_occurrence_id |
| MEASUREMENT | person_id | PERSON | person_id |
| MEASUREMENT | visit_occurrence_id | VISIT_OCCURRENCE | visit_occurrence_id |
| OBSERVATION | person_id | PERSON | person_id |
| OBSERVATION | visit_occurrence_id | VISIT_OCCURRENCE | visit_occurrence_id |
| SPECIMEN | person_id | PERSON | person_id |
| FILE_ASSET | assay_id | ASSAY | assay_id |
| GROUP_ACCESS | person_id | PERSON | person_id |

### Self-referencing FKs

| Table | Column | References |
|---|---|---|
| VISIT_OCCURRENCE | preceding_visit_occurrence_id | VISIT_OCCURRENCE.visit_occurrence_id |
| FILE_ASSET | derived_from_file_asset_id | FILE_ASSET.file_asset_id |

---

## 2. Polymorphic foreign keys — field-level

These point to the primary key of another table. Two columns work together: an **id
column** holds the target row's PK value, and a **field concept column** holds a
`Field`-class concept whose name is a `table.column` — telling you which table/column the
id resolves against. There is no native SQL FK; resolution is enforced at the
ETL/application layer.

Tables with a field-level polymorphic pointer in our set:

| Table | Id column | Field-concept column | Purpose |
|---|---|---|---|
| MEASUREMENT | measurement_event_id | meas_event_field_concept_id | link a measurement to the record it derives from |
| OBSERVATION | observation_event_id | obs_event_field_concept_id | link an observation to a related record |
| GROUP_ACCESS | record_id | field_concept_id | the governed record a grant applies to |

### Resolution map (field concept → table.column)

| field_concept_id | concept_name | target table | target column |
|---|---|---|---|
| 1147026 | person.person_id | PERSON | person_id |
| 1147044 | observation_period.observation_period_id | OBSERVATION_PERIOD | observation_period_id |
| 1147070 | visit_occurrence.visit_occurrence_id | VISIT_OCCURRENCE | visit_occurrence_id |
| 1147127 | condition_occurrence.condition_occurrence_id | CONDITION_OCCURRENCE | condition_occurrence_id |
| 1147082 | procedure_occurrence.procedure_occurrence_id | PROCEDURE_OCCURRENCE | procedure_occurrence_id |
| 1147138 | measurement.measurement_id | MEASUREMENT | measurement_id |
| 1147165 | observation.observation_id | OBSERVATION | observation_id |
| 1147049 | specimen.specimen_id | SPECIMEN | specimen_id |
| 2000000101 | assay.assay_id | ASSAY | assay_id |
| 2000000102 | file_asset.file_asset_id | FILE_ASSET | file_asset_id |

Valid-target differences by consumer:

- **MEASUREMENT / OBSERVATION event pointers** may target clinical tables **and** the
  custom tables (ASSAY, FILE_ASSET).
- **GROUP_ACCESS** targets the **eight governed person-scoped tables only** (person,
  observation_period, visit, condition, procedure, measurement, observation, specimen).
  ASSAY and FILE_ASSET are ungoverned (see §5), so `group_access.field_concept_id` never
  uses `2000000101`/`2000000102`.

**PERSON is grant-gated, not public.** The PERSON row is governed like any clinical
record: a group can resolve a `person_id` only if it holds a grant for that person
(`group_access` row with `field_concept_id = 1147026`). PERSON is **not** made public or
exempted from the filter — that was considered and rejected, because a public/exempt
PERSON would let any group enumerate every `person_id` and thereby infer the existence and
total count of people it has no access to. Per-group grants on PERSON close that
population-size leak and keep PERSON consistent with the rest of the model. In practice a
person's PERSON-row grants are the union of the groups that hold a grant on any of that
person's records.

---

## 3. FACT_RELATIONSHIP — table-level

FACT_RELATIONSHIP relates any two records within the same instance that lack a dedicated
FK. It resolves at the **table** level, not the field level: `domain_concept_id_1/2` hold
a `Table`-class metadata concept identifying the table, and `fact_id_1/2` hold the PK
value in that table. `relationship_concept_id` (Relationship vocabulary) names the link;
rows are stored bidirectionally.

This is the key difference from §2: the event/governance pointers name a `table.column`
(`Field` class); FACT_RELATIONSHIP names only the `table` (`Table` class).

### Resolution map (domain concept → table)

Use `Table`-class concepts (`concept_class_id = 'Table'`, `domain_id = 'Metadata'`), **not**
the clinical-domain concepts (19, 21, 27, …) the old doc used.

| domain_concept_id (Table class) | target table |
|---|---|
| 1147314 | PERSON |
| 1147321 | OBSERVATION_PERIOD |
| 1147332 | VISIT_OCCURRENCE |
| 1147333 | CONDITION_OCCURRENCE |
| 1147301 | PROCEDURE_OCCURRENCE |
| 1147330 | MEASUREMENT |
| 1147304 | OBSERVATION |
| 1147306 | SPECIMEN |
| 1147325 | CDM_SOURCE |
| 1147320 | FACT_RELATIONSHIP |

> All ids confirmed against the instance CONCEPT table (`concept_class_id = 'Table'`,
> `domain_id = 'Metadata'`). Custom tables are not expected as FACT_RELATIONSHIP targets in
> our model (they connect via the §2 event pointer); if that changes, they would need a
> custom `Table`-class concept in the ≥2-billion range.

---

## 4. Concept-ID conventions

| Use | Concept class | Where | Example |
|---|---|---|---|
| Field-level polymorphic resolver | `Field` (`table.column`) | §2 event & GROUP_ACCESS | `1147138` = measurement.measurement_id |
| Table-level polymorphic resolver | `Table` (`table`) | §3 FACT_RELATIONSHIP | `1147314` = PERSON |

Rules:

- **Standard concepts** for these resolvers live in the OMOP CDM/Metadata vocabulary in
  the ~`1147xxx` range, loaded from the OMOP Standardized Vocabularies (download from OHDSI
  Athena, https://athena.ohdsi.org — a prerequisite for this whole table set). Where OMOP has
  two valid ids for the same `table.column` (different CDM releases), use the **lower (older)**
  id for broad compatibility.
- **Custom tables** need local concepts. OMOP reserves `concept_id ≥ 2,000,000,000` for
  custom/local concepts so they never collide with standard vocabulary. Ours:
  - `2000000101` = `assay.assay_id`
  - `2000000102` = `file_asset.file_asset_id`
- The clinical-**Domain** concepts (e.g., 21 = Measurement) are **not** used for any of
  these polymorphic keys in our implementation.

---

## 5. Custom tables — key summary

**ASSAY** — PK `assay_id`. No outbound entity FK. Reached two ways: `FILE_ASSET.assay_id`
(native FK) and as a field-level polymorphic target of a MEASUREMENT/OBSERVATION event
(`2000000101`). Carries no person linkage itself.

**FILE_ASSET** — PK `file_asset_id`. Native FK `assay_id → ASSAY`; self-FK
`derived_from_file_asset_id → FILE_ASSET`. Polymorphic target via `2000000102`. The file
itself is governed by the curators' external use-agreement process, not by GROUP_ACCESS.

**GROUP_ACCESS** — composite PK (`field_concept_id`, `record_id`, `grant_group`). Native
FK `person_id → PERSON`. `record_id` is a field-level polymorphic pointer (resolved by
`field_concept_id`) to a governed clinical record; it has no native FK by design. Governs
the clinical tables only.
