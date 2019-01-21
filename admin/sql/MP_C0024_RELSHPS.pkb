
/*****************************************************************************
--  Note: This generated code is for demonstration purposes only and may
--        not be deployable.
*****************************************************************************/

CREATE OR REPLACE PACKAGE ""MP_C0024_RELSHPS"" AS
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
"XXOD_HZ_IMP_RELSHIPS_INT_St" BOOLEAN := FALSE; 

"P_BATCH_ID" NUMBER;"P_AOPS_BATCH_ID" NUMBER;"CS_0_CR" VARCHAR2(30) := 'XXCONV';"CS_1_ST" DATE := '01-JAN-1990';

-- Function Main 
-- Entry point in package ""MP_C0024_RELSHPS""
FUNCTION Main("P_BATCH_ID" IN NUMBER
 DEFAULT NULL, "P_AOPS_BATCH_ID" IN NUMBER
 DEFAULT NULL) RETURN NUMBER;  

END ""MP_C0024_RELSHPS"";

/

CREATE OR REPLACE PACKAGE BODY ""MP_C0024_RELSHPS"" AS




---------------------------------------------------------------------------
-- Function "XXOD_HZ_IMP_RELSHIPS_INT_Bat"
--   performs batch extraction
--   Returns TRUE on success
--   Returns FALSE on failure
---------------------------------------------------------------------------
FUNCTION "XXOD_HZ_IMP_RELSHIPS_INT_Bat" ("P_BATCH_ID" IN NUMBER
 DEFAULT NULL, "P_AOPS_BATCH_ID" IN NUMBER
 DEFAULT NULL) 
 RETURN BOOLEAN IS

BEGIN
  EXECUTE IMMEDIATE 'ALTER SESSION ENABLE PARALLEL DML';

  BEGIN
    INSERT
    INTO
      "XXOD_HZ_IMP_RELSHIPS_INT"
      ("BATCH_ID",
      "CREATED_BY_MODULE",
      "OBJ_ORIG_SYSTEM",
      "OBJ_ORIG_SYSTEM_REFERENCE",
      "RELATIONSHIP_CODE",
      "RELATIONSHIP_TYPE",
      "START_DATE",
      "SUB_ORIG_SYSTEM",
      "SUB_ORIG_SYSTEM_REFERENCE")
      (SELECT
/*+ NO_MERGE */
  "MP_C0024_RELSHPS"."P_BATCH_ID" "P_BATCH_ID$1",
  "MP_C0024_RELSHPS"."CS_0_CR" "CRTBYMOD",
  "RELSHPS"."RL_OBJ_ORG_SYS" "RL_OBJ_ORG_SYS",
  "RELSHPS"."RL_OBJ_ORIG_SREF" "RL_OBJ_ORIG_SREF",
  "RELSHPS"."RL_REL_CODE" "RL_REL_CODE",
  "RELSHPS"."RL_REL_TYPE" "RL_REL_TYPE",
  "MP_C0024_RELSHPS"."CS_1_ST" "STRTDT",
  "RELSHPS"."RL_SBJ_ORG_SYS" "RL_SBJ_ORG_SYS",
  "RELSHPS"."RL_SBJ_ORIG_SREF" "RL_SBJ_ORIG_SREF"
FROM
  "SIMPLIFY"."RELSHPS"@"GANDHI.NA.ODCORP.NET" "RELSHPS"
  WHERE 
  ( "RELSHPS"."BATCH_NBR" = "MP_C0024_RELSHPS"."P_AOPS_BATCH_ID" )
      );
    COMMIT;
  EXCEPTION WHEN OTHERS THEN
    ROLLBACK;
    COMMIT;
    RETURN FALSE;
  END;
  COMMIT;
  RETURN TRUE;
END "XXOD_HZ_IMP_RELSHIPS_INT_Bat";

FUNCTION Main("P_BATCH_ID" IN NUMBER
 DEFAULT NULL, "P_AOPS_BATCH_ID" IN NUMBER
 DEFAULT NULL) RETURN NUMBER IS
get_batch_status           BOOLEAN := TRUE;
BEGIN
  -- Mapping input parameter global variable assignments
  "MP_C0024_RELSHPS"."P_BATCH_ID" := "MP_C0024_RELSHPS".Main."P_BATCH_ID";"MP_C0024_RELSHPS"."P_AOPS_BATCH_ID" := "MP_C0024_RELSHPS".Main."P_AOPS_BATCH_ID";
  

  
  
  
  
  
PROCEDURE EXEC_AUTONOMOUS_SQL(CMD IN VARCHAR2) IS
  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
  EXECUTE IMMEDIATE (CMD);
  COMMIT;
END;
  -- Initialize all batch status variables
	"XXOD_HZ_IMP_RELSHIPS_INT_St" := FALSE;



			
"XXOD_HZ_IMP_RELSHIPS_INT_St" := "XXOD_HZ_IMP_RELSHIPS_INT_Bat"; 


RETURN get_status;
END Main;
END ""MP_C0024_RELSHPS"";

/

