SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK ON
SET TERM ON

PROMPT Creating PACKAGE XX_CRM_SFA_LEAD_REP

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

 CREATE OR REPLACE
 PACKAGE apps.XX_CRM_SFA_LEAD_REP
 AS
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : XX_CRM_SFA_LEAD_REP                                                 |
-- | Description : This Package is used to check the status of the Customer information|
-- |               of the Errored HVOP data.                                           |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 17-DEC-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : MASTER                                                              |
-- | Description : This procedure is used to fetch the lead details and write in output|
-- |               file with tab as delimiter.                                         |
-- | Parameters  :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 17-DEC-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+

    PROCEDURE LEAD_REP ( p_errbuf               OUT VARCHAR2
                        ,p_retcode              OUT VARCHAR2
                        ,p_in_start_date        IN  VARCHAR2
                        ,p_in_end_date          IN  VARCHAR2
                        ,p_in_status_category   IN  VARCHAR2
                        ,p_in_status            IN  VARCHAR2
                        ,p_in_source            IN  VARCHAR2
                        ,p_in_last_update_date  IN  VARCHAR2
                        );

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : PRINT_OUTPUT                                                        |
-- | Description : This procedure is used to print the output.                         |
-- |                                                                                   |
-- | Parameters  :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 17-DEC-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+
    PROCEDURE PRINT_OUTPUT ( p_message   IN VARCHAR2);

 END XX_CRM_SFA_LEAD_REP;

/
SHO ERROR