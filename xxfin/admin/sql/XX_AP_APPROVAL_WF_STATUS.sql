REM================================================================================================
REM                                 Start Of Script
REM================================================================================================
SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- |      Oracle NAIO/Office Depot/Consulting Organization                 |
-- +=======================================================================+
-- | Name        : XX_AP_APPROVAL_WF_STATUS.sql		                   |
-- | Description : Script to change the wf approval status from 'INITIATED'|
-- |               to 'REQUIRED'.                                          |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- | 1.0     20-Oct-2008  P.Suresh          Defect 11755.                  |
-- | 1.2     12-FEB-2009  P.Marco           Defect 12621.
-- +=======================================================================+
WHENEVER SQLERROR CONTINUE

PROMPT
PROMPT Updating ap_invoices_all.wfapproval_status to 'REQUIRED'
PROMPT

UPDATE ap_invoices_all
   SET wfapproval_status = 'REQUIRED'
 WHERE wfapproval_status = 'INITIATED'
   AND source <> 'Manual Invoice Entry';   -- added per defect 12621

COMMIT;

--EXIT;
REM================================================================================================
REM                                 Start Of Script
REM================================================================================================