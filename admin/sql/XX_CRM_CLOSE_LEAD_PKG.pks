SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package XX_CRM_CLOSE_LEAD_PKG

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE XX_CRM_CLOSE_LEAD_PKG
AS

-- +========================================================================+
-- |                  Office Depot - Project Simplify                       |
-- |                       WIPRO Technologies                               |
-- +========================================================================+
-- | Name        : XX_CRM_CLOSE_LEAD_PKG                                    |
-- | Description : 1) Systematically Close out ALL leads that have not been |
-- |                  touched or updated in 250 days and greater.           |
-- |                                                                        |
-- |               2) Systematically Close out Leads with a Status of " New"|
-- |                  that have not been touched or updated in 180 days.    |
-- |                                                                        |
-- |Change Record:                                                          |
-- |===============                                                         |
-- |Version   Date          Author              Remarks                     |
-- |=======  ==========   ==================    ============================|
-- |1.0      18-JUN-2010  Anitha Devarajulu     Initial version             |
-- |2.0      01-JUL-2010                        Added Lead Number parameter |
-- +========================================================================+

-- +========================================================================+
-- | Name        : UPDATE_TO_CLOSE_LEAD                                     |
-- | Description : 1) Systematically Close out ALL leads that have not been |
-- |                  touched or updated in 250 days and greater.           |
-- |                                                                        |
-- |               2) Systematically Close out Leads with a Status of " New"|
-- |                  that have not been touched or updated in 180 days.    |
-- | Returns     : x_error_buf, x_ret_code                                  |
-- +========================================================================+

   PROCEDURE UPDATE_TO_CLOSE_LEAD (
                                    x_error_buf          OUT VARCHAR2
                                   ,x_ret_code           OUT NUMBER
                                   ,p_status             IN  VARCHAR2
                                   ,p_no_of_days         IN  NUMBER
                                   ,p_close_reason       IN  VARCHAR2
				   ,p_update             IN  VARCHAR2
                                   ,p_lead_number        IN  NUMBER
                                   );


   PROCEDURE REVERT_BACK_CLOSE_LEAD_DATA (
                                    x_error_buf          OUT VARCHAR2
                                   ,x_ret_code           OUT NUMBER                                   
                                   ,P_REQUEST_ID         IN  NUMBER
                                   ,P_RECORDS_TO_UPDATE  IN  NUMBER
                                   ,P_LEAD_NUMBER        IN  NUMBER
                                   ,P_REVERT_TO_DATE     IN  VARCHAR2
                                   );



END XX_CRM_CLOSE_LEAD_PKG;
/
SHOW ERR

EXIT