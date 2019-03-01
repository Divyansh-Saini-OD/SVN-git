CREATE OR REPLACE PACKAGE CYBER_FLEX_PKG AS
-- -----------------------------------------------------------------------------
-- Copyright 2014 CA
-- All Rights Reserved
--
-- Name           : CYBER_FLEX_PKG
-- Creation Date  : Jan 2014
-- Author         : Art Muszynski
--
-- Description : CA package for dealing with Flex Fields while interfacing with 
--                Oracle Application Concurrent Manager.
--
-- Dependencies Tables        : None
-- Dependencies Views         : None
-- Dependencies Sequences     : None
-- Dependencies Procedures    : None
-- Dependencies Functions     : None
-- Dependencies Packages      : FND_PROFILE, FND_CONCURRENT, FND_REQUEST
-- Dependencies Types         : None
-- Dependencies Database Links: None
--
-- Modification History:
--
-- Date         Name           Modifications
-- ------------ -------------- ----------------------------------------------------
-- 29-Jan-2014  Art Muszynski  Initial package using data from Bharath Ram Danda from Schneider
--------------- -------------- ----------------------------------------------------

TYPE table_r IS RECORD(
     table_name             fnd_flex_validation_tables.application_table_name%TYPE,
     id_column_name         fnd_flex_validation_tables.id_column_name%TYPE,
     id_column_type         fnd_flex_validation_tables.id_column_type%TYPE,
     value_column_name      fnd_flex_validation_tables.value_column_name%TYPE,
     value_column_type      fnd_flex_validation_tables.value_column_type%TYPE,
     meaning_column_name    fnd_flex_validation_tables.meaning_column_name%TYPE,
     where_clause           fnd_flex_validation_tables.additional_where_clause%TYPE,
     start_date_column_name fnd_flex_validation_tables.start_date_column_name%TYPE,
     end_date_column_name   fnd_flex_validation_tables.end_date_column_name%TYPE);

TYPE valueset_r IS RECORD(
     vsid                 fnd_flex_values.flex_value_set_id%TYPE,
     name                 fnd_flex_value_sets.flex_value_set_name%TYPE,
     validation_type      fnd_flex_value_sets.validation_type%TYPE,
     table_info           table_r);


/* public */
TYPE valueset_dr IS RECORD(
     format_type                fnd_flex_value_sets.format_type%TYPE,
     alphanumeric_allowed_flag  fnd_flex_value_sets.alphanumeric_allowed_flag%TYPE,
     uppercase_only_flag        fnd_flex_value_sets.uppercase_only_flag%TYPE,
     numeric_mode_flag          fnd_flex_value_sets.numeric_mode_enabled_flag%TYPE,
     max_size                   fnd_flex_value_sets.maximum_size%TYPE,
     max_value                  fnd_flex_value_sets.maximum_value%TYPE,
     min_value                  fnd_flex_value_sets.minimum_value%TYPE,
     longlist_enabled           BOOLEAN,
     has_id                     BOOLEAN,
     has_meaning                BOOLEAN,
     longlist_flag              fnd_flex_value_sets.longlist_flag%TYPE);


TYPE value_dr IS RECORD(
     id                 fnd_flex_values_vl.flex_value%TYPE,
     value              fnd_flex_values_vl.flex_value%TYPE,
     meaning            fnd_flex_values_vl.description%TYPE,
     start_date_active  fnd_flex_values_vl.start_date_active%TYPE,
     end_date_active    fnd_flex_values_vl.end_date_active%TYPE,
     parent_flex_value_low  fnd_flex_values_vl.parent_flex_value_low%TYPE);


CURSOR value_c(
       valueset IN valueset_r,
       enabled  IN fnd_flex_values.enabled_flag%TYPE)
       RETURN value_dr;

CURSOR value_d(
       valueset IN valueset_r,
       enabled  IN fnd_flex_values.enabled_flag%TYPE)
       RETURN value_dr;

PROCEDURE get_valueset(valueset_id IN  fnd_flex_values.flex_value_set_id%TYPE,
               valueset    OUT nocopy valueset_r,
               format      OUT nocopy valueset_dr);

PROCEDURE get_value_init(valueset          IN valueset_r,
             enabled_only      IN  BOOLEAN,
                         p_flex_field_name IN VARCHAR2,
                         p_flexfield_value_set IN VARCHAR2,
                         p_request_set_short_name IN VARCHAR2);

PROCEDURE get_value(valueset     IN  valueset_r,
            rowcount     OUT nocopy NUMBER,
            found        OUT nocopy BOOLEAN,
            value        OUT nocopy value_dr);

PROCEDURE get_value_end(valueset   IN valueset_r);


PROCEDURE DEBUG(state IN BOOLEAN);
FUNCTION get_valueset_sql(p_flex_valueset_id IN NUMBER) RETURN VARCHAR2;
FUNCTION convert_value_to_id(p_flex_field_name     IN VARCHAR2,
                             p_flexfield_value_set IN VARCHAR2,
                             p_request_set_short_name IN VARCHAR2,
                             p_flex_valueset_id IN NUMBER,
                             p_value IN VARCHAR2,
                             p_parsed_where_clause IN VARCHAR2) RETURN VARCHAR2;
    
END CYBER_FLEX_PKG;
/
