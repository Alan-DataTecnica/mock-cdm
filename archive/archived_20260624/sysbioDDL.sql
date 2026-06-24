-- ============================================================
-- Custom OMOP CDM v5.4 subset — DDL
-- Standard tables (clinical + vocabulary) + custom (ASSAY, FILE_ASSET) + governance (GROUP_ACCESS)
-- Dropped from standard CDM: VISIT_DETAIL, PROVIDER, CARE_SITE, LOCATION (and unused domains)
-- Replace @cdmDatabaseSchema with your schema name before running.
-- ============================================================

-- ---------- VOCABULARY TABLES ----------
-- These are created EMPTY. Populate them with the OMOP Standardized Vocabularies downloaded
-- from OHDSI Athena (https://athena.ohdsi.org) before loading any data: the governance
-- field/table-concept resolvers (~1147xxx) and concept_id 0 ('No matching concept') come from
-- that vocabulary set, and the *_concept_id foreign keys below will not satisfy without it.
CREATE TABLE @cdmDatabaseSchema.CONCEPT (
			concept_id integer NOT NULL,
			concept_name varchar(255) NOT NULL,
			domain_id varchar(20) NOT NULL,
			vocabulary_id varchar(20) NOT NULL,
			concept_class_id varchar(20) NOT NULL,
			standard_concept varchar(1) NULL,
			concept_code varchar(50) NOT NULL,
			valid_start_date date NOT NULL,
			valid_end_date date NOT NULL,
			invalid_reason varchar(1) NULL );
CREATE TABLE @cdmDatabaseSchema.VOCABULARY (
			vocabulary_id varchar(20) NOT NULL,
			vocabulary_name varchar(255) NOT NULL,
			vocabulary_reference varchar(255) NULL,
			vocabulary_version varchar(255) NULL,
			vocabulary_concept_id integer NOT NULL );
CREATE TABLE @cdmDatabaseSchema.DOMAIN (
			domain_id varchar(20) NOT NULL,
			domain_name varchar(255) NOT NULL,
			domain_concept_id integer NOT NULL );
CREATE TABLE @cdmDatabaseSchema.CONCEPT_CLASS (
			concept_class_id varchar(20) NOT NULL,
			concept_class_name varchar(255) NOT NULL,
			concept_class_concept_id integer NOT NULL );
CREATE TABLE @cdmDatabaseSchema.CONCEPT_RELATIONSHIP (
			concept_id_1 integer NOT NULL,
			concept_id_2 integer NOT NULL,
			relationship_id varchar(20) NOT NULL,
			valid_start_date date NOT NULL,
			valid_end_date date NOT NULL,
			invalid_reason varchar(1) NULL );
CREATE TABLE @cdmDatabaseSchema.RELATIONSHIP (
			relationship_id varchar(20) NOT NULL,
			relationship_name varchar(255) NOT NULL,
			is_hierarchical varchar(1) NOT NULL,
			defines_ancestry varchar(1) NOT NULL,
			reverse_relationship_id varchar(20) NOT NULL,
			relationship_concept_id integer NOT NULL );
CREATE TABLE @cdmDatabaseSchema.CONCEPT_SYNONYM (
			concept_id integer NOT NULL,
			concept_synonym_name varchar(1000) NOT NULL,
			language_concept_id integer NOT NULL );
CREATE TABLE @cdmDatabaseSchema.CONCEPT_ANCESTOR (
			ancestor_concept_id integer NOT NULL,
			descendant_concept_id integer NOT NULL,
			min_levels_of_separation integer NOT NULL,
			max_levels_of_separation integer NOT NULL );
CREATE TABLE @cdmDatabaseSchema.SOURCE_TO_CONCEPT_MAP (
			source_code varchar(50) NOT NULL,
			source_concept_id integer NOT NULL,
			source_vocabulary_id varchar(20) NOT NULL,
			source_code_description varchar(255) NULL,
			target_concept_id integer NOT NULL,
			target_vocabulary_id varchar(20) NOT NULL,
			valid_start_date date NOT NULL,
			valid_end_date date NOT NULL,
			invalid_reason varchar(1) NULL );
CREATE TABLE @cdmDatabaseSchema.DRUG_STRENGTH (
			drug_concept_id integer NOT NULL,
			ingredient_concept_id integer NOT NULL,
			amount_value NUMERIC NULL,
			amount_unit_concept_id integer NULL,
			numerator_value NUMERIC NULL,
			numerator_unit_concept_id integer NULL,
			denominator_value NUMERIC NULL,
			denominator_unit_concept_id integer NULL,
			box_size integer NULL,
			valid_start_date date NOT NULL,
			valid_end_date date NOT NULL,
			invalid_reason varchar(1) NULL );

-- ---------- CLINICAL / METADATA TABLES ----------
CREATE TABLE @cdmDatabaseSchema.PERSON (
			person_id integer NOT NULL,
			gender_concept_id integer NOT NULL,
			year_of_birth integer NOT NULL,
			month_of_birth integer NULL,
			day_of_birth integer NULL,
			birth_datetime TIMESTAMP NULL,
			race_concept_id integer NOT NULL,
			ethnicity_concept_id integer NOT NULL,
			location_id integer NULL,
			provider_id integer NULL,
			care_site_id integer NULL,
			person_source_value varchar(50) NULL,
			gender_source_value varchar(50) NULL,
			gender_source_concept_id integer NULL,
			race_source_value varchar(50) NULL,
			race_source_concept_id integer NULL,
			ethnicity_source_value varchar(50) NULL,
			ethnicity_source_concept_id integer NULL );
CREATE TABLE @cdmDatabaseSchema.OBSERVATION_PERIOD (
			observation_period_id integer NOT NULL,
			person_id integer NOT NULL,
			observation_period_start_date date NOT NULL,
			observation_period_end_date date NOT NULL,
			period_type_concept_id integer NOT NULL );
CREATE TABLE @cdmDatabaseSchema.VISIT_OCCURRENCE (
			visit_occurrence_id integer NOT NULL,
			person_id integer NOT NULL,
			visit_concept_id integer NOT NULL,
			visit_start_date date NOT NULL,
			visit_start_datetime TIMESTAMP NULL,
			visit_end_date date NOT NULL,
			visit_end_datetime TIMESTAMP NULL,
			visit_type_concept_id Integer NOT NULL,
			provider_id integer NULL,
			care_site_id integer NULL,
			visit_source_value varchar(50) NULL,
			visit_source_concept_id integer NULL,
			admitted_from_concept_id integer NULL,
			admitted_from_source_value varchar(50) NULL,
			discharged_to_concept_id integer NULL,
			discharged_to_source_value varchar(50) NULL,
			preceding_visit_occurrence_id integer NULL );
CREATE TABLE @cdmDatabaseSchema.CONDITION_OCCURRENCE (
			condition_occurrence_id integer NOT NULL,
			person_id integer NOT NULL,
			condition_concept_id integer NOT NULL,
			condition_start_date date NOT NULL,
			condition_start_datetime TIMESTAMP NULL,
			condition_end_date date NULL,
			condition_end_datetime TIMESTAMP NULL,
			condition_type_concept_id integer NOT NULL,
			condition_status_concept_id integer NULL,
			stop_reason varchar(20) NULL,
			provider_id integer NULL,
			visit_occurrence_id integer NULL,
			visit_detail_id integer NULL,
			condition_source_value varchar(50) NULL,
			condition_source_concept_id integer NULL,
			condition_status_source_value varchar(50) NULL );
CREATE TABLE @cdmDatabaseSchema.PROCEDURE_OCCURRENCE (
			procedure_occurrence_id integer NOT NULL,
			person_id integer NOT NULL,
			procedure_concept_id integer NOT NULL,
			procedure_date date NOT NULL,
			procedure_datetime TIMESTAMP NULL,
			procedure_end_date date NULL,
			procedure_end_datetime TIMESTAMP NULL,
			procedure_type_concept_id integer NOT NULL,
			modifier_concept_id integer NULL,
			quantity integer NULL,
			provider_id integer NULL,
			visit_occurrence_id integer NULL,
			visit_detail_id integer NULL,
			procedure_source_value varchar(50) NULL,
			procedure_source_concept_id integer NULL,
			modifier_source_value varchar(50) NULL );
CREATE TABLE @cdmDatabaseSchema.MEASUREMENT (
			measurement_id integer NOT NULL,
			person_id integer NOT NULL,
			measurement_concept_id integer NOT NULL,
			measurement_date date NOT NULL,
			measurement_datetime TIMESTAMP NULL,
			measurement_time varchar(10) NULL,
			measurement_type_concept_id integer NOT NULL,
			operator_concept_id integer NULL,
			value_as_number NUMERIC NULL,
			value_as_concept_id integer NULL,
			unit_concept_id integer NULL,
			range_low NUMERIC NULL,
			range_high NUMERIC NULL,
			provider_id integer NULL,
			visit_occurrence_id integer NULL,
			visit_detail_id integer NULL,
			measurement_source_value varchar(50) NULL,
			measurement_source_concept_id integer NULL,
			unit_source_value varchar(50) NULL,
			unit_source_concept_id integer NULL,
			value_source_value varchar(50) NULL,
			measurement_event_id bigint NULL,
			meas_event_field_concept_id integer NULL );
CREATE TABLE @cdmDatabaseSchema.OBSERVATION (
			observation_id integer NOT NULL,
			person_id integer NOT NULL,
			observation_concept_id integer NOT NULL,
			observation_date date NOT NULL,
			observation_datetime TIMESTAMP NULL,
			observation_type_concept_id integer NOT NULL,
			value_as_number NUMERIC NULL,
			value_as_string varchar(60) NULL,
			value_as_concept_id Integer NULL,
			qualifier_concept_id integer NULL,
			unit_concept_id integer NULL,
			provider_id integer NULL,
			visit_occurrence_id integer NULL,
			visit_detail_id integer NULL,
			observation_source_value varchar(50) NULL,
			observation_source_concept_id integer NULL,
			unit_source_value varchar(50) NULL,
			qualifier_source_value varchar(50) NULL,
			value_source_value varchar(50) NULL,
			observation_event_id bigint NULL,
			obs_event_field_concept_id integer NULL );
CREATE TABLE @cdmDatabaseSchema.SPECIMEN (
			specimen_id integer NOT NULL,
			person_id integer NOT NULL,
			specimen_concept_id integer NOT NULL,
			specimen_type_concept_id integer NOT NULL,
			specimen_date date NOT NULL,
			specimen_datetime TIMESTAMP NULL,
			quantity NUMERIC NULL,
			unit_concept_id integer NULL,
			anatomic_site_concept_id integer NULL,
			disease_status_concept_id integer NULL,
			specimen_source_id varchar(50) NULL,
			specimen_source_value varchar(50) NULL,
			unit_source_value varchar(50) NULL,
			anatomic_site_source_value varchar(50) NULL,
			disease_status_source_value varchar(50) NULL );
CREATE TABLE @cdmDatabaseSchema.FACT_RELATIONSHIP (
			domain_concept_id_1 integer NOT NULL,
			fact_id_1 integer NOT NULL,
			domain_concept_id_2 integer NOT NULL,
			fact_id_2 integer NOT NULL,
			relationship_concept_id integer NOT NULL );
CREATE TABLE @cdmDatabaseSchema.CDM_SOURCE (
			cdm_source_name varchar(255) NOT NULL,
			cdm_source_abbreviation varchar(25) NOT NULL,
			cdm_holder varchar(255) NOT NULL,
			source_description TEXT NULL,
			source_documentation_reference varchar(255) NULL,
			cdm_etl_reference varchar(255) NULL,
			source_release_date date NOT NULL,
			cdm_release_date date NOT NULL,
			cdm_version varchar(10) NULL,
			cdm_version_concept_id integer NOT NULL,
			vocabulary_version varchar(20) NOT NULL );

-- ---------- CUSTOM TABLES ----------
CREATE TABLE @cdmDatabaseSchema.ASSAY (
			assay_id varchar(50) NOT NULL,
			assay_type varchar(50) NOT NULL,
			platform varchar(50) NOT NULL,
			suspension_type varchar(50) NULL,
			analyte_type varchar(50) NULL );

CREATE TABLE @cdmDatabaseSchema.FILE_ASSET (
			file_asset_id varchar(50) NOT NULL,
			assay_id varchar(50) NOT NULL,
			derived_from_file_asset_id varchar(50) NULL,
			file_name varchar(255) NULL,
			file_format varchar(50) NULL,
			file_role varchar(50) NULL,
			uri varchar(2000) NULL,
			access_level varchar(50) NULL );

-- ---------- GOVERNANCE TABLE ----------
CREATE TABLE @cdmDatabaseSchema.GROUP_ACCESS (
			field_concept_id integer NOT NULL,   -- which table record_id refers to (polymorphic resolver)
			record_id bigint NOT NULL,           -- granted record id (polymorphic; no FK)
			grant_group varchar(50) NOT NULL,    -- group permitted to see the record ('public' = all)
			person_id integer NOT NULL );        -- person the record belongs to (access key + visibility match)

-- ---------- PRIMARY KEYS ----------
ALTER TABLE @cdmDatabaseSchema.PERSON ADD CONSTRAINT xpk_PERSON PRIMARY KEY (person_id);
ALTER TABLE @cdmDatabaseSchema.OBSERVATION_PERIOD ADD CONSTRAINT xpk_OBSERVATION_PERIOD PRIMARY KEY (observation_period_id);
ALTER TABLE @cdmDatabaseSchema.VISIT_OCCURRENCE ADD CONSTRAINT xpk_VISIT_OCCURRENCE PRIMARY KEY (visit_occurrence_id);
ALTER TABLE @cdmDatabaseSchema.CONDITION_OCCURRENCE ADD CONSTRAINT xpk_CONDITION_OCCURRENCE PRIMARY KEY (condition_occurrence_id);
ALTER TABLE @cdmDatabaseSchema.PROCEDURE_OCCURRENCE ADD CONSTRAINT xpk_PROCEDURE_OCCURRENCE PRIMARY KEY (procedure_occurrence_id);
ALTER TABLE @cdmDatabaseSchema.MEASUREMENT ADD CONSTRAINT xpk_MEASUREMENT PRIMARY KEY (measurement_id);
ALTER TABLE @cdmDatabaseSchema.OBSERVATION ADD CONSTRAINT xpk_OBSERVATION PRIMARY KEY (observation_id);
ALTER TABLE @cdmDatabaseSchema.SPECIMEN ADD CONSTRAINT xpk_SPECIMEN PRIMARY KEY (specimen_id);
ALTER TABLE @cdmDatabaseSchema.CONCEPT ADD CONSTRAINT xpk_CONCEPT PRIMARY KEY (concept_id);
ALTER TABLE @cdmDatabaseSchema.VOCABULARY ADD CONSTRAINT xpk_VOCABULARY PRIMARY KEY (vocabulary_id);
ALTER TABLE @cdmDatabaseSchema.DOMAIN ADD CONSTRAINT xpk_DOMAIN PRIMARY KEY (domain_id);
ALTER TABLE @cdmDatabaseSchema.CONCEPT_CLASS ADD CONSTRAINT xpk_CONCEPT_CLASS PRIMARY KEY (concept_class_id);
ALTER TABLE @cdmDatabaseSchema.RELATIONSHIP ADD CONSTRAINT xpk_RELATIONSHIP PRIMARY KEY (relationship_id);
ALTER TABLE @cdmDatabaseSchema.ASSAY ADD CONSTRAINT xpk_ASSAY PRIMARY KEY (assay_id);
ALTER TABLE @cdmDatabaseSchema.FILE_ASSET ADD CONSTRAINT xpk_FILE_ASSET PRIMARY KEY (file_asset_id);
ALTER TABLE @cdmDatabaseSchema.GROUP_ACCESS ADD CONSTRAINT xpk_GROUP_ACCESS PRIMARY KEY (field_concept_id, record_id, grant_group);

-- ---------- SENTINEL CHECKS ----------
-- Real demographics live in governed OBSERVATION rows, NEVER on PERSON. These pin the
-- PERSON demographic concept fields to OMOP's standard 'No matching concept' (0), so the
-- database physically rejects any attempt to store a real value here, regardless of loader.
-- (year_of_birth is intentionally NOT checked yet — its placeholder value is undecided and
--  unstandardized; pin it only once that value is chosen.)
ALTER TABLE @cdmDatabaseSchema.PERSON ADD CONSTRAINT chk_PERSON_gender_sentinel    CHECK (gender_concept_id = 0);
ALTER TABLE @cdmDatabaseSchema.PERSON ADD CONSTRAINT chk_PERSON_race_sentinel      CHECK (race_concept_id = 0);
ALTER TABLE @cdmDatabaseSchema.PERSON ADD CONSTRAINT chk_PERSON_ethnicity_sentinel CHECK (ethnicity_concept_id = 0);

-- ---------- FOREIGN KEYS (only between included tables; FKs to dropped tables removed) ----------
ALTER TABLE @cdmDatabaseSchema.PERSON ADD CONSTRAINT fpk_PERSON_gender_concept_id FOREIGN KEY (gender_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.PERSON ADD CONSTRAINT fpk_PERSON_race_concept_id FOREIGN KEY (race_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.PERSON ADD CONSTRAINT fpk_PERSON_ethnicity_concept_id FOREIGN KEY (ethnicity_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.PERSON ADD CONSTRAINT fpk_PERSON_gender_source_concept_id FOREIGN KEY (gender_source_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.PERSON ADD CONSTRAINT fpk_PERSON_race_source_concept_id FOREIGN KEY (race_source_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.PERSON ADD CONSTRAINT fpk_PERSON_ethnicity_source_concept_id FOREIGN KEY (ethnicity_source_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.OBSERVATION_PERIOD ADD CONSTRAINT fpk_OBSERVATION_PERIOD_person_id FOREIGN KEY (person_id) REFERENCES @cdmDatabaseSchema.PERSON (PERSON_ID);
ALTER TABLE @cdmDatabaseSchema.OBSERVATION_PERIOD ADD CONSTRAINT fpk_OBSERVATION_PERIOD_period_type_concept_id FOREIGN KEY (period_type_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.VISIT_OCCURRENCE ADD CONSTRAINT fpk_VISIT_OCCURRENCE_person_id FOREIGN KEY (person_id) REFERENCES @cdmDatabaseSchema.PERSON (PERSON_ID);
ALTER TABLE @cdmDatabaseSchema.VISIT_OCCURRENCE ADD CONSTRAINT fpk_VISIT_OCCURRENCE_visit_concept_id FOREIGN KEY (visit_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.VISIT_OCCURRENCE ADD CONSTRAINT fpk_VISIT_OCCURRENCE_visit_type_concept_id FOREIGN KEY (visit_type_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.VISIT_OCCURRENCE ADD CONSTRAINT fpk_VISIT_OCCURRENCE_visit_source_concept_id FOREIGN KEY (visit_source_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.VISIT_OCCURRENCE ADD CONSTRAINT fpk_VISIT_OCCURRENCE_admitted_from_concept_id FOREIGN KEY (admitted_from_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.VISIT_OCCURRENCE ADD CONSTRAINT fpk_VISIT_OCCURRENCE_discharged_to_concept_id FOREIGN KEY (discharged_to_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.VISIT_OCCURRENCE ADD CONSTRAINT fpk_VISIT_OCCURRENCE_preceding_visit_occurrence_id FOREIGN KEY (preceding_visit_occurrence_id) REFERENCES @cdmDatabaseSchema.VISIT_OCCURRENCE (VISIT_OCCURRENCE_ID);
ALTER TABLE @cdmDatabaseSchema.CONDITION_OCCURRENCE ADD CONSTRAINT fpk_CONDITION_OCCURRENCE_person_id FOREIGN KEY (person_id) REFERENCES @cdmDatabaseSchema.PERSON (PERSON_ID);
ALTER TABLE @cdmDatabaseSchema.CONDITION_OCCURRENCE ADD CONSTRAINT fpk_CONDITION_OCCURRENCE_condition_concept_id FOREIGN KEY (condition_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.CONDITION_OCCURRENCE ADD CONSTRAINT fpk_CONDITION_OCCURRENCE_condition_type_concept_id FOREIGN KEY (condition_type_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.CONDITION_OCCURRENCE ADD CONSTRAINT fpk_CONDITION_OCCURRENCE_condition_status_concept_id FOREIGN KEY (condition_status_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.CONDITION_OCCURRENCE ADD CONSTRAINT fpk_CONDITION_OCCURRENCE_visit_occurrence_id FOREIGN KEY (visit_occurrence_id) REFERENCES @cdmDatabaseSchema.VISIT_OCCURRENCE (VISIT_OCCURRENCE_ID);
ALTER TABLE @cdmDatabaseSchema.CONDITION_OCCURRENCE ADD CONSTRAINT fpk_CONDITION_OCCURRENCE_condition_source_concept_id FOREIGN KEY (condition_source_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.PROCEDURE_OCCURRENCE ADD CONSTRAINT fpk_PROCEDURE_OCCURRENCE_person_id FOREIGN KEY (person_id) REFERENCES @cdmDatabaseSchema.PERSON (PERSON_ID);
ALTER TABLE @cdmDatabaseSchema.PROCEDURE_OCCURRENCE ADD CONSTRAINT fpk_PROCEDURE_OCCURRENCE_procedure_concept_id FOREIGN KEY (procedure_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.PROCEDURE_OCCURRENCE ADD CONSTRAINT fpk_PROCEDURE_OCCURRENCE_procedure_type_concept_id FOREIGN KEY (procedure_type_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.PROCEDURE_OCCURRENCE ADD CONSTRAINT fpk_PROCEDURE_OCCURRENCE_modifier_concept_id FOREIGN KEY (modifier_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.PROCEDURE_OCCURRENCE ADD CONSTRAINT fpk_PROCEDURE_OCCURRENCE_visit_occurrence_id FOREIGN KEY (visit_occurrence_id) REFERENCES @cdmDatabaseSchema.VISIT_OCCURRENCE (VISIT_OCCURRENCE_ID);
ALTER TABLE @cdmDatabaseSchema.PROCEDURE_OCCURRENCE ADD CONSTRAINT fpk_PROCEDURE_OCCURRENCE_procedure_source_concept_id FOREIGN KEY (procedure_source_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.MEASUREMENT ADD CONSTRAINT fpk_MEASUREMENT_person_id FOREIGN KEY (person_id) REFERENCES @cdmDatabaseSchema.PERSON (PERSON_ID);
ALTER TABLE @cdmDatabaseSchema.MEASUREMENT ADD CONSTRAINT fpk_MEASUREMENT_measurement_concept_id FOREIGN KEY (measurement_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.MEASUREMENT ADD CONSTRAINT fpk_MEASUREMENT_measurement_type_concept_id FOREIGN KEY (measurement_type_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.MEASUREMENT ADD CONSTRAINT fpk_MEASUREMENT_operator_concept_id FOREIGN KEY (operator_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.MEASUREMENT ADD CONSTRAINT fpk_MEASUREMENT_value_as_concept_id FOREIGN KEY (value_as_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.MEASUREMENT ADD CONSTRAINT fpk_MEASUREMENT_unit_concept_id FOREIGN KEY (unit_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.MEASUREMENT ADD CONSTRAINT fpk_MEASUREMENT_visit_occurrence_id FOREIGN KEY (visit_occurrence_id) REFERENCES @cdmDatabaseSchema.VISIT_OCCURRENCE (VISIT_OCCURRENCE_ID);
ALTER TABLE @cdmDatabaseSchema.MEASUREMENT ADD CONSTRAINT fpk_MEASUREMENT_measurement_source_concept_id FOREIGN KEY (measurement_source_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.MEASUREMENT ADD CONSTRAINT fpk_MEASUREMENT_unit_source_concept_id FOREIGN KEY (unit_source_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.MEASUREMENT ADD CONSTRAINT fpk_MEASUREMENT_meas_event_field_concept_id FOREIGN KEY (meas_event_field_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.OBSERVATION ADD CONSTRAINT fpk_OBSERVATION_person_id FOREIGN KEY (person_id) REFERENCES @cdmDatabaseSchema.PERSON (PERSON_ID);
ALTER TABLE @cdmDatabaseSchema.OBSERVATION ADD CONSTRAINT fpk_OBSERVATION_observation_concept_id FOREIGN KEY (observation_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.OBSERVATION ADD CONSTRAINT fpk_OBSERVATION_observation_type_concept_id FOREIGN KEY (observation_type_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.OBSERVATION ADD CONSTRAINT fpk_OBSERVATION_value_as_concept_id FOREIGN KEY (value_as_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.OBSERVATION ADD CONSTRAINT fpk_OBSERVATION_qualifier_concept_id FOREIGN KEY (qualifier_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.OBSERVATION ADD CONSTRAINT fpk_OBSERVATION_unit_concept_id FOREIGN KEY (unit_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.OBSERVATION ADD CONSTRAINT fpk_OBSERVATION_visit_occurrence_id FOREIGN KEY (visit_occurrence_id) REFERENCES @cdmDatabaseSchema.VISIT_OCCURRENCE (VISIT_OCCURRENCE_ID);
ALTER TABLE @cdmDatabaseSchema.OBSERVATION ADD CONSTRAINT fpk_OBSERVATION_observation_source_concept_id FOREIGN KEY (observation_source_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.OBSERVATION ADD CONSTRAINT fpk_OBSERVATION_obs_event_field_concept_id FOREIGN KEY (obs_event_field_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.SPECIMEN ADD CONSTRAINT fpk_SPECIMEN_person_id FOREIGN KEY (person_id) REFERENCES @cdmDatabaseSchema.PERSON (PERSON_ID);
ALTER TABLE @cdmDatabaseSchema.SPECIMEN ADD CONSTRAINT fpk_SPECIMEN_specimen_concept_id FOREIGN KEY (specimen_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.SPECIMEN ADD CONSTRAINT fpk_SPECIMEN_specimen_type_concept_id FOREIGN KEY (specimen_type_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.SPECIMEN ADD CONSTRAINT fpk_SPECIMEN_unit_concept_id FOREIGN KEY (unit_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.SPECIMEN ADD CONSTRAINT fpk_SPECIMEN_anatomic_site_concept_id FOREIGN KEY (anatomic_site_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.SPECIMEN ADD CONSTRAINT fpk_SPECIMEN_disease_status_concept_id FOREIGN KEY (disease_status_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.FACT_RELATIONSHIP ADD CONSTRAINT fpk_FACT_RELATIONSHIP_domain_concept_id_1 FOREIGN KEY (domain_concept_id_1) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.FACT_RELATIONSHIP ADD CONSTRAINT fpk_FACT_RELATIONSHIP_domain_concept_id_2 FOREIGN KEY (domain_concept_id_2) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.FACT_RELATIONSHIP ADD CONSTRAINT fpk_FACT_RELATIONSHIP_relationship_concept_id FOREIGN KEY (relationship_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.CDM_SOURCE ADD CONSTRAINT fpk_CDM_SOURCE_cdm_version_concept_id FOREIGN KEY (cdm_version_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.CONCEPT ADD CONSTRAINT fpk_CONCEPT_domain_id FOREIGN KEY (domain_id) REFERENCES @cdmDatabaseSchema.DOMAIN (DOMAIN_ID);
ALTER TABLE @cdmDatabaseSchema.CONCEPT ADD CONSTRAINT fpk_CONCEPT_vocabulary_id FOREIGN KEY (vocabulary_id) REFERENCES @cdmDatabaseSchema.VOCABULARY (VOCABULARY_ID);
ALTER TABLE @cdmDatabaseSchema.CONCEPT ADD CONSTRAINT fpk_CONCEPT_concept_class_id FOREIGN KEY (concept_class_id) REFERENCES @cdmDatabaseSchema.CONCEPT_CLASS (CONCEPT_CLASS_ID);
ALTER TABLE @cdmDatabaseSchema.VOCABULARY ADD CONSTRAINT fpk_VOCABULARY_vocabulary_concept_id FOREIGN KEY (vocabulary_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.DOMAIN ADD CONSTRAINT fpk_DOMAIN_domain_concept_id FOREIGN KEY (domain_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.CONCEPT_CLASS ADD CONSTRAINT fpk_CONCEPT_CLASS_concept_class_concept_id FOREIGN KEY (concept_class_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.CONCEPT_RELATIONSHIP ADD CONSTRAINT fpk_CONCEPT_RELATIONSHIP_concept_id_1 FOREIGN KEY (concept_id_1) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.CONCEPT_RELATIONSHIP ADD CONSTRAINT fpk_CONCEPT_RELATIONSHIP_concept_id_2 FOREIGN KEY (concept_id_2) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.CONCEPT_RELATIONSHIP ADD CONSTRAINT fpk_CONCEPT_RELATIONSHIP_relationship_id FOREIGN KEY (relationship_id) REFERENCES @cdmDatabaseSchema.RELATIONSHIP (RELATIONSHIP_ID);
ALTER TABLE @cdmDatabaseSchema.RELATIONSHIP ADD CONSTRAINT fpk_RELATIONSHIP_relationship_concept_id FOREIGN KEY (relationship_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.CONCEPT_SYNONYM ADD CONSTRAINT fpk_CONCEPT_SYNONYM_concept_id FOREIGN KEY (concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.CONCEPT_SYNONYM ADD CONSTRAINT fpk_CONCEPT_SYNONYM_language_concept_id FOREIGN KEY (language_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.CONCEPT_ANCESTOR ADD CONSTRAINT fpk_CONCEPT_ANCESTOR_ancestor_concept_id FOREIGN KEY (ancestor_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.CONCEPT_ANCESTOR ADD CONSTRAINT fpk_CONCEPT_ANCESTOR_descendant_concept_id FOREIGN KEY (descendant_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.SOURCE_TO_CONCEPT_MAP ADD CONSTRAINT fpk_SOURCE_TO_CONCEPT_MAP_source_concept_id FOREIGN KEY (source_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.SOURCE_TO_CONCEPT_MAP ADD CONSTRAINT fpk_SOURCE_TO_CONCEPT_MAP_target_concept_id FOREIGN KEY (target_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.SOURCE_TO_CONCEPT_MAP ADD CONSTRAINT fpk_SOURCE_TO_CONCEPT_MAP_target_vocabulary_id FOREIGN KEY (target_vocabulary_id) REFERENCES @cdmDatabaseSchema.VOCABULARY (VOCABULARY_ID);
ALTER TABLE @cdmDatabaseSchema.DRUG_STRENGTH ADD CONSTRAINT fpk_DRUG_STRENGTH_drug_concept_id FOREIGN KEY (drug_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.DRUG_STRENGTH ADD CONSTRAINT fpk_DRUG_STRENGTH_ingredient_concept_id FOREIGN KEY (ingredient_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.DRUG_STRENGTH ADD CONSTRAINT fpk_DRUG_STRENGTH_amount_unit_concept_id FOREIGN KEY (amount_unit_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.DRUG_STRENGTH ADD CONSTRAINT fpk_DRUG_STRENGTH_numerator_unit_concept_id FOREIGN KEY (numerator_unit_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
ALTER TABLE @cdmDatabaseSchema.DRUG_STRENGTH ADD CONSTRAINT fpk_DRUG_STRENGTH_denominator_unit_concept_id FOREIGN KEY (denominator_unit_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (CONCEPT_ID);
-- custom + governance FKs
ALTER TABLE @cdmDatabaseSchema.FILE_ASSET ADD CONSTRAINT fpk_FILE_ASSET_assay_id FOREIGN KEY (assay_id) REFERENCES @cdmDatabaseSchema.ASSAY (assay_id);
ALTER TABLE @cdmDatabaseSchema.FILE_ASSET ADD CONSTRAINT fpk_FILE_ASSET_derived FOREIGN KEY (derived_from_file_asset_id) REFERENCES @cdmDatabaseSchema.FILE_ASSET (file_asset_id);
ALTER TABLE @cdmDatabaseSchema.GROUP_ACCESS ADD CONSTRAINT fpk_GROUP_ACCESS_person_id FOREIGN KEY (person_id) REFERENCES @cdmDatabaseSchema.PERSON (person_id);
ALTER TABLE @cdmDatabaseSchema.GROUP_ACCESS ADD CONSTRAINT fpk_GROUP_ACCESS_field_concept_id FOREIGN KEY (field_concept_id) REFERENCES @cdmDatabaseSchema.CONCEPT (concept_id);

-- ---------- INDICES ----------
CREATE INDEX idx_person_id  ON @cdmDatabaseSchema.person  (person_id ASC);
CREATE INDEX idx_gender ON @cdmDatabaseSchema.person (gender_concept_id ASC);
CREATE INDEX idx_observation_period_id_1  ON @cdmDatabaseSchema.observation_period  (person_id ASC);
CREATE INDEX idx_visit_person_id_1  ON @cdmDatabaseSchema.visit_occurrence  (person_id ASC);
CREATE INDEX idx_visit_concept_id_1 ON @cdmDatabaseSchema.visit_occurrence (visit_concept_id ASC);
CREATE INDEX idx_condition_person_id_1  ON @cdmDatabaseSchema.condition_occurrence  (person_id ASC);
CREATE INDEX idx_condition_concept_id_1 ON @cdmDatabaseSchema.condition_occurrence (condition_concept_id ASC);
CREATE INDEX idx_condition_visit_id_1 ON @cdmDatabaseSchema.condition_occurrence (visit_occurrence_id ASC);
CREATE INDEX idx_procedure_person_id_1  ON @cdmDatabaseSchema.procedure_occurrence  (person_id ASC);
CREATE INDEX idx_procedure_concept_id_1 ON @cdmDatabaseSchema.procedure_occurrence (procedure_concept_id ASC);
CREATE INDEX idx_procedure_visit_id_1 ON @cdmDatabaseSchema.procedure_occurrence (visit_occurrence_id ASC);
CREATE INDEX idx_measurement_person_id_1  ON @cdmDatabaseSchema.measurement  (person_id ASC);
CREATE INDEX idx_measurement_concept_id_1 ON @cdmDatabaseSchema.measurement (measurement_concept_id ASC);
CREATE INDEX idx_measurement_visit_id_1 ON @cdmDatabaseSchema.measurement (visit_occurrence_id ASC);
CREATE INDEX idx_observation_person_id_1  ON @cdmDatabaseSchema.observation  (person_id ASC);
CREATE INDEX idx_observation_concept_id_1 ON @cdmDatabaseSchema.observation (observation_concept_id ASC);
CREATE INDEX idx_observation_visit_id_1 ON @cdmDatabaseSchema.observation (visit_occurrence_id ASC);
CREATE INDEX idx_specimen_person_id_1  ON @cdmDatabaseSchema.specimen  (person_id ASC);
CREATE INDEX idx_specimen_concept_id_1 ON @cdmDatabaseSchema.specimen (specimen_concept_id ASC);
CREATE INDEX idx_fact_relationship_id1 ON @cdmDatabaseSchema.fact_relationship (domain_concept_id_1 ASC);
CREATE INDEX idx_fact_relationship_id2 ON @cdmDatabaseSchema.fact_relationship (domain_concept_id_2 ASC);
CREATE INDEX idx_fact_relationship_id3 ON @cdmDatabaseSchema.fact_relationship (relationship_concept_id ASC);
CREATE INDEX idx_concept_concept_id  ON @cdmDatabaseSchema.concept  (concept_id ASC);
CREATE INDEX idx_concept_code ON @cdmDatabaseSchema.concept (concept_code ASC);
CREATE INDEX idx_concept_vocabluary_id ON @cdmDatabaseSchema.concept (vocabulary_id ASC);
CREATE INDEX idx_concept_domain_id ON @cdmDatabaseSchema.concept (domain_id ASC);
CREATE INDEX idx_concept_class_id ON @cdmDatabaseSchema.concept (concept_class_id ASC);
CREATE INDEX idx_vocabulary_vocabulary_id  ON @cdmDatabaseSchema.vocabulary  (vocabulary_id ASC);
CREATE INDEX idx_domain_domain_id  ON @cdmDatabaseSchema.domain  (domain_id ASC);
CREATE INDEX idx_concept_class_class_id  ON @cdmDatabaseSchema.concept_class  (concept_class_id ASC);
CREATE INDEX idx_concept_relationship_id_1  ON @cdmDatabaseSchema.concept_relationship  (concept_id_1 ASC);
CREATE INDEX idx_concept_relationship_id_2 ON @cdmDatabaseSchema.concept_relationship (concept_id_2 ASC);
CREATE INDEX idx_concept_relationship_id_3 ON @cdmDatabaseSchema.concept_relationship (relationship_id ASC);
CREATE INDEX idx_relationship_rel_id  ON @cdmDatabaseSchema.relationship  (relationship_id ASC);
CREATE INDEX idx_concept_synonym_id  ON @cdmDatabaseSchema.concept_synonym  (concept_id ASC);
CREATE INDEX idx_concept_ancestor_id_1  ON @cdmDatabaseSchema.concept_ancestor  (ancestor_concept_id ASC);
CREATE INDEX idx_concept_ancestor_id_2 ON @cdmDatabaseSchema.concept_ancestor (descendant_concept_id ASC);
CREATE INDEX idx_source_to_concept_map_3  ON @cdmDatabaseSchema.source_to_concept_map  (target_concept_id ASC);
CREATE INDEX idx_source_to_concept_map_1 ON @cdmDatabaseSchema.source_to_concept_map (source_vocabulary_id ASC);
CREATE INDEX idx_source_to_concept_map_2 ON @cdmDatabaseSchema.source_to_concept_map (target_vocabulary_id ASC);
CREATE INDEX idx_source_to_concept_map_c ON @cdmDatabaseSchema.source_to_concept_map (source_code ASC);
CREATE INDEX idx_drug_strength_id_1  ON @cdmDatabaseSchema.drug_strength  (drug_concept_id ASC);
CREATE INDEX idx_drug_strength_id_2 ON @cdmDatabaseSchema.drug_strength (ingredient_concept_id ASC);
CREATE INDEX idx_group_access_person ON @cdmDatabaseSchema.GROUP_ACCESS (person_id, grant_group);
CREATE INDEX idx_group_access_record ON @cdmDatabaseSchema.GROUP_ACCESS (field_concept_id, record_id);
