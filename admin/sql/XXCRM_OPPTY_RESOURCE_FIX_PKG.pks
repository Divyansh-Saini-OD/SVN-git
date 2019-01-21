
SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT CREATING PACKAGE SPECIFICATION XXCRM_OPPTY_RESOURCE_FIX_PKG
PROMPT PROGRAM EXITS IF THE CREATION IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE XXCRM_OPPTY_RESOURCE_FIX_PKG

AS

 -- +===========================================================================+
 -- |===========================================================================|
 -- |                  Office Depot - Project Simplify                          |
 -- |                       WIPRO Technologies                                  |
 -- +===========================================================================+
 -- | Name        : XXCRM_OPPTY_RESOURCE_FIX_PKG                                |
 -- |                                                                           |
 -- | Description : Data Fix for the Invalid Resource_id and Group_id           |
 -- |               for the given opportunity number and status.                |
 -- |                                                                           |
 -- |Change Record:                                                             |
 -- |===============                                                            |
 -- |Version   Date            Author              Remarks                      |
 -- |=======   ==========    =============        ==============================|
 -- |1.0       03-AUG-10      RenuPriya           Initial version               |
 -- |1.1       14-SEP-10      Navin Agarwal       Code Changes for Defect 6089  |
 -- |                                                                           |
 -- |===========================================================================|
 -- +===========================================================================+

   PROCEDURE Update_Opp_Rec_From_Access (p_errbuf              OUT NOCOPY VARCHAR2
                                        ,p_retcode             OUT NOCOPY VARCHAR2
                                        ,p_opportunity_number  IN VARCHAR2
                                        ,p_lead_status         IN  VARCHAR2
                                        ,p_commit              IN VARCHAR2
                                        );

END XXCRM_OPPTY_RESOURCE_FIX_PKG;
/
SHOW ERR;