SET SHOW OFF;
SET VERIFY OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;

WHENEVER SQLERROR CONTINUE;

WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_CDH_EBL_UTIL_PKG
  -- +======================================================================================+
  -- |                  Office Depot - Project Simplify                                     |
  -- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization                          |
  -- +======================================================================================|
  -- | Name       : XX_CDH_EBL_UTIL_PKG                                                     |
  -- | Description: This package is the Wrapper for  inserting the log entries into the     |
  -- |              table  XX_CDH_EBL_LOG                                                   |
  -- |                                                                                      |
  -- |                                                                                      |
  -- |Change Record:                                                                        |
  -- |===============                                                                       |
  -- |Version     Date            Author               Remarks                              |
  -- |=======   ===========   =================     ========================================|
  -- |DRAFT 1A  08-APR-2010   Mangala                   Initial draft version               |
  -- |                                                                                      |
  -- |======================================================================================|
  -- | Subversion Info:                                                                     |
  -- | $HeadURL$                                                                          |
  -- | $Rev$                                                                        |
  -- | $Date$                                |
  -- |                                                                                      |
  -- +======================================================================================+
AS
  -- +=====================================================================================+
  -- | Name             : LOG_ERROR                                                        |
  -- | Description      : This procedure shall insert error messages into XX_CDH_EBL_LOG   |
  -- |                                                                                     |
  -- +=====================================================================================+

  PROCEDURE LOG_ERROR(p_msg VARCHAR2)
  IS
    PRAGMA AUTONOMOUS_TRANSACTION ;
  BEGIN
     IF NVL(FND_PROFILE.VALUE('XXOD_EBL_DEBUG_LOG'),'N')='Y' THEN
        INSERT INTO XX_CDH_EBL_LOG
        VALUES(XX_CDH_EBL_SEQ_S.NEXTVAL
              ,p_msg
              ,SYSDATE
              ,FND_GLOBAL.user_id
              );
        COMMIT;
     ELSE
        ROLLBACK;
     END IF;
  EXCEPTION
  WHEN OTHERS THEN
     ROLLBACK;
  END LOG_ERROR;

END XX_CDH_EBL_UTIL_PKG;
/
SHOW ERRORS;