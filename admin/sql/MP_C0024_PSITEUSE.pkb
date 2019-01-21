
/*****************************************************************************
--  Note: This generated code is for demonstration purposes only and may
--        not be deployable.
*****************************************************************************/

CREATE OR REPLACE PACKAGE ""MP_C0024_PSITEUSE"" AS
OWB$MAP_OBJECT_ID VARCHAR2(32) := '';
sql_stmt  VARCHAR2(32767);
get_abort BOOLEAN := FALSE;
get_abort_procedure BOOLEAN := FALSE;
get_trigger_success BOOLEAN := TRUE;
get_errors NUMBER(22) := 0;
get_status NUMBER(22) := 0;
get_error_ratio NUMBER(22) := 0;
get_global_names              VARCHAR2(10) := 'FALSE';
-- Status variable for Batch cursors
"XXOD_HZ_IMP_ADDRESSUSES_INT_St" BOOLEAN := FALSE; 

"P_BATCH_ID" NUMBER;"P_AOPS_BATCH_ID" NUMBER;"CS_0_CR" VARCHAR2(30) := 'XXCONV';

-- Function Main 
-- Entry point in package ""MP_C0024_PSITEUSE""
FUNCTION Main("P_BATCH_ID" IN NUMBER
 DEFAULT NULL, "P_AOPS_BATCH_ID" IN NUMBER
 DEFAULT NULL) RETURN NUMBER;  

END ""MP_C0024_PSITEUSE"";

/

CREATE OR REPLACE PACKAGE BODY ""MP_C0024_PSITEUSE"" AS




---------------------------------------------------------------------------
-- Function "XXOD_HZ_IMP_ADDRESSUSES_I_Bat"
--   performs batch extraction
--   Returns TRUE on success
--   Returns FALSE on failure
---------------------------------------------------------------------------
FUNCTION "XXOD_HZ_IMP_ADDRESSUSES_I_Bat" ("P_BATCH_ID" IN NUMBER
 DEFAULT NULL, "P_AOPS_BATCH_ID" IN NUMBER
 DEFAULT NULL) 
 RETURN BOOLEAN IS

BEGIN
  EXECUTE IMMEDIATE 'ALTER SESSION ENABLE PARALLEL DML';

  BEGIN
    INSERT
    INTO
      "XXOD_HZ_IMP_ADDRESSUSES_INT"
      ("BATCH_ID",
      "CREATED_BY_MODULE",
      "PARTY_ORIG_SYSTEM",
      "PARTY_ORIG_SYSTEM_REFERENCE",
      "PRIMARY_FLAG",
      "SITE_ORIG_SYSTEM",
      "SITE_ORIG_SYSTEM_REFERENCE",
      "SITE_USE_TYPE")
      (SELECT
/*+ NO_MERGE */
  "MP_C0024_PSITEUSE"."P_BATCH_ID" "P_BATCH_ID$1",
  "MP_C0024_PSITEUSE"."CS_0_CR" "CRTBYMOD",
  "PSITEUSE"."PU_PARTY_ORG_SYS" "PU_PARTY_ORG_SYS",
  "PSITEUSE"."PU_PARTY_ORIG_SREF" "PU_PARTY_ORIG_SREF",
  "PSITEUSE"."PU_PRIMRY" "PU_PRIMRY",
  "PSITEUSE"."PU_SITE_ORG_SYS" "PU_SITE_ORG_SYS",
  "PSITEUSE"."PU_SITE_ORIG_SREF" "PU_SITE_ORIG_SREF",
  "PSITEUSE"."PU_SITE_USER_TYPE" "PU_SITE_USER_TYPE"
FROM
  "SIMPLIFY"."PSITEUSE"@"GANDHI.NA.ODCORP.NET" "PSITEUSE"
  WHERE 
  ( "PSITEUSE"."BATCH_NBR" = "MP_C0024_PSITEUSE"."P_AOPS_BATCH_ID" )
      );
    COMMIT;
  EXCEPTION WHEN OTHERS THEN
    ROLLBACK;
    COMMIT;
    RETURN FALSE;
  END;
  COMMIT;
  RETURN TRUE;
END "XXOD_HZ_IMP_ADDRESSUSES_I_Bat";

FUNCTION Main("P_BATCH_ID" IN NUMBER
 DEFAULT NULL, "P_AOPS_BATCH_ID" IN NUMBER
 DEFAULT NULL) RETURN NUMBER IS
get_batch_status           BOOLEAN := TRUE;
BEGIN
  -- Mapping input parameter global variable assignments
  "MP_C0024_PSITEUSE"."P_BATCH_ID" := "MP_C0024_PSITEUSE".Main."P_BATCH_ID";"MP_C0024_PSITEUSE"."P_AOPS_BATCH_ID" := "MP_C0024_PSITEUSE".Main."P_AOPS_BATCH_ID";
  

  
  
  
  
  
PROCEDURE EXEC_AUTONOMOUS_SQL(CMD IN VARCHAR2) IS
  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
  EXECUTE IMMEDIATE (CMD);
  COMMIT;
END;
  -- Initialize all batch status variables
	"XXOD_HZ_IMP_ADDRESSUSES_INT_St" := FALSE;



			
"XXOD_HZ_IMP_ADDRESSUSES_INT_St" := "XXOD_HZ_IMP_ADDRESSUSES_I_Bat"; 


RETURN get_status;
END Main;
END ""MP_C0024_PSITEUSE"";

/

