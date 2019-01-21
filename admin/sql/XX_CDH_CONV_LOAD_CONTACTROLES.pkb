SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_CDH_CONV_LOAD_CONTACTROLES
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_CDH_CONV_LOAD_CONTACTROLES.pkb                  |
-- | Description :  New CDH Customer Conversion Seamless Package Spec  |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |DRAFT 1a  10-Aug-2011 Sreedhar Mohan     Initial draft version     |
-- +===================================================================+
AS
---------------------------------------------------------------------------
-- Procedure load_contact_roles
--   performs batch Load

---------------------------------------------------------------------------
  PROCEDURE load_contact_roles
   ( x_errbuf                   OUT VARCHAR2
    ,x_retcode                  OUT VARCHAR2
    ,p_batch_id                 IN NUMBER
   ) IS

BEGIN
  EXECUTE IMMEDIATE 'ALTER SESSION ENABLE PARALLEL DML';

    INSERT
    INTO
      "HZ_IMP_CONTACTROLES_INT"
      ("BATCH_ID",
      "CONTACT_ORIG_SYSTEM",
      "CONTACT_ORIG_SYSTEM_REFERENCE",
      "SUB_ORIG_SYSTEM",
      "SUB_ORIG_SYSTEM_REFERENCE",
      "ROLE_TYPE",
      "INSERT_UPDATE_FLAG",
      "INTERFACE_STATUS",
      "ERROR_ID",
      "CREATION_DATE",
      "CREATED_BY",
      "LAST_UPDATE_DATE",
      "LAST_UPDATED_BY",
      "LAST_UPDATE_LOGIN",
      "REQUEST_ID",
      "PROGRAM_APPLICATION_ID",
      "PROGRAM_ID",
      "PROGRAM_UPDATE_DATE",
      "CREATED_BY_MODULE")
      (SELECT
  p_batch_id,
  TRIM ( "XXOD_HZ_IMP_CONTACTROLES_INT"."CONTACT_ORIG_SYSTEM"  )/* EXP_TRIM.OUT_CONTACTROLES_INT.CONTACT_ORIG_SYSTEM */ "CONTACT_ORIG_SYSTEM",
  TRIM (  "XXOD_HZ_IMP_CONTACTROLES_INT"."CONTACT_ORIG_SYSTEM_REFERENCE" )/* EXP_TRIM.OUT_CONTACTROLES_INT.CONTACT_ORIG_SYSTEM_REFERENCE */ "CONTACT_ORIG_SYSTEM_REFERENCE",
  TRIM (  "XXOD_HZ_IMP_CONTACTROLES_INT"."SUB_ORIG_SYSTEM" )/* EXP_TRIM.OUT_CONTACTROLES_INT.SUB_ORIG_SYSTEM */ "SUB_ORIG_SYSTEM",
  TRIM (  "XXOD_HZ_IMP_CONTACTROLES_INT"."SUB_ORIG_SYSTEM_REFERENCE" )/* EXP_TRIM.OUT_CONTACTROLES_INT.SUB_ORIG_SYSTEM_REFERENCE */ "SUB_ORIG_SYSTEM_REFERENCE",
  TRIM (  "XXOD_HZ_IMP_CONTACTROLES_INT"."ROLE_TYPE" )/* EXP_TRIM.OUT_CONTACTROLES_INT.ROLE_TYPE */ "ROLE_TYPE",
  TRIM ( "XXOD_HZ_IMP_CONTACTROLES_INT"."INSERT_UPDATE_FLAG" )/* EXP_TRIM.OUT_CONTACTROLES_INT.INSERT_UPDATE_FLAG */ "INSERT_UPDATE_FLAG",
  TRIM (  "XXOD_HZ_IMP_CONTACTROLES_INT"."INTERFACE_STATUS" )/* EXP_TRIM.OUT_CONTACTROLES_INT.INTERFACE_STATUS */ "INTERFACE_STATUS",
  "XXOD_HZ_IMP_CONTACTROLES_INT"."ERROR_ID" "ERROR_ID",
  "XXOD_HZ_IMP_CONTACTROLES_INT"."CREATION_DATE" "CREATION_DATE",
  "XXOD_HZ_IMP_CONTACTROLES_INT"."CREATED_BY" "CREATED_BY",
  "XXOD_HZ_IMP_CONTACTROLES_INT"."LAST_UPDATE_DATE" "LAST_UPDATE_DATE",
  "XXOD_HZ_IMP_CONTACTROLES_INT"."LAST_UPDATED_BY" "LAST_UPDATED_BY",
  "XXOD_HZ_IMP_CONTACTROLES_INT"."LAST_UPDATE_LOGIN" "LAST_UPDATE_LOGIN",
  "XXOD_HZ_IMP_CONTACTROLES_INT"."REQUEST_ID" "REQUEST_ID",
  "XXOD_HZ_IMP_CONTACTROLES_INT"."PROGRAM_APPLICATION_ID" "PROGRAM_APPLICATION_ID",
  "XXOD_HZ_IMP_CONTACTROLES_INT"."PROGRAM_ID" "PROGRAM_ID",
  "XXOD_HZ_IMP_CONTACTROLES_INT"."PROGRAM_UPDATE_DATE" "PROGRAM_UPDATE_DATE",
  TRIM (  "XXOD_HZ_IMP_CONTACTROLES_INT"."CREATED_BY_MODULE" )/* EXP_TRIM.OUT_CONTACTROLES_INT.CREATED_BY_MODULE */ "CREATED_BY_MODULE"
FROM
  "XXOD_HZ_IMP_CONTACTROLES_INT" "XXOD_HZ_IMP_CONTACTROLES_INT"
  WHERE
  ( "XXOD_HZ_IMP_CONTACTROLES_INT"."BATCH_ID" = p_batch_id )
      );
	--update output for no. of records
    fnd_file.put_line(fnd_file.output,'No. of records inserted in  HZ_IMP_CONTACTROLES_INT: ' ||SQL%ROWCOUNT);
    COMMIT;
EXCEPTION WHEN OTHERS THEN
   fnd_file.put_line(fnd_file.log,'Exception in Load_accounts: ' ||SQLERRM);
   ROLLBACK;
END load_contact_roles;

END XX_CDH_CONV_LOAD_CONTACTROLES;
/
SHOW ERRORS;
