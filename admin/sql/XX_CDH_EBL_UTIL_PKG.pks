SET SHOW OFF;
SET VERIFY OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE
PACKAGE XX_CDH_EBL_UTIL_PKG AUTHID CURRENT_USER
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
  -- | $Rev$                                                                              |
  -- | $Date$                                                                             |
  -- |                                                                                      |
  -- +======================================================================================+
AS
  -- +=====================================================================================+
  -- | Name             : LOG_ERROR                                                        |
  -- | Description      : This procedure shall insert error messages into XX_CDH_EBL_LOG   |
  -- |                    .                                                                |
  -- |                                                                                     |
  -- +=====================================================================================+

  procedure LOG_ERROR(p_msg VARCHAR2);
 
END XX_CDH_EBL_UTIL_PKG;
/ 

SHOW ERRORS;
