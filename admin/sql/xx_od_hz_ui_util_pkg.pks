create or replace
PACKAGE xx_od_hz_ui_util_pkg IS

  -- Author  : Sunildev
  -- Created : 01-Jun-11 1:51:37 PM
  -- Purpose : 

  -- Public type declarations
  FUNCTION check_row_deleteable
  (
    p_entity_name   IN VARCHAR2
   , -- table name
    p_data_source   IN VARCHAR2 DEFAULT NULL
   , -- if applicable
    p_entity_pk1    IN VARCHAR2
   , -- primary key
    p_entity_pk2    IN VARCHAR2 DEFAULT NULL
   , -- primary key pt. 2
    p_party_id      IN NUMBER DEFAULT NULL
   , -- only pass if available
    p_function_name IN VARCHAR2 DEFAULT NULL -- function name
  ) RETURN VARCHAR2;

END xx_od_hz_ui_util_pkg;
/