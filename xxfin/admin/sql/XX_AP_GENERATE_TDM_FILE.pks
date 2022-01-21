SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE XX_AP_GENERATE_TDM_FILE

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE
CREATE OR REPLACE PACKAGE XX_AP_GENERATE_TDM_FILE AS
-- +====================================================================+
-- |                  Office Depot - Project Simplify                   |
-- |                       WIPRO Technologies                           |
-- +====================================================================+
-- | Name        : OD : WRITE TO TDM                                    |
-- | Rice ID     : R1050                                                |
-- | Description : Formats the contents of the XXAPRTVAPDM              |
-- |               and XXAPCHBKAPDM and writes them intoo a data file   |
-- |               for CR 542 for Defect 3327                           |
-- |                                                                    |
-- |Change Record:                                                      |
-- |===============                                                     |
-- | Version       Date             Author             Remarks          |
-- |=========   ==========     ===============     =================    |
-- |  1.0       29-Jun-2010    Priyanka Nagesh       Initial version    |
-- +====================================================================+
-- +====================================================================+
-- | Name        : XX_WRITE_TO_FILE                                     |
-- | Description : Formats the contents of the XXAPRTVAPDM              |
-- |               and XXAPCHBKAPDM and writes them into a data file    |
-- |               for CR 542 for Defect 3327                           |
-- | Parameters  : p_report_type,p_app_char and p_request_id            |
-- +====================================================================+
    PROCEDURE XX_WRITE_TO_FILE(p_report_type        IN VARCHAR2
                              ,p_app_char              NUMBER
                              ,p_request_id         IN NUMBER
                              );
END XX_AP_GENERATE_TDM_FILE;
/
SHOW ERROR
