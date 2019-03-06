 -- +========================================================================+
   -- |                  Office Depot - Project Simplify                       |
   -- |                  Office Depot                                          |
   -- +========================================================================+
   -- | Name  :      XX_OM_SAS_HVOP_RECON.syn                                  |
   -- | Description:  This file  grants access to apps for custom table        |
   -- |               required for SAS HVOP Reconciliation                     |
   -- |                                                                        |
   -- |Change Record:                                                          |
   -- |===============                                                         |
   -- |Version   Date          Author              Remarks                     |
   -- |=======   ==========  =============    =================================|
   -- |1.0       25-Jun-2008   Sachin Thaker  Initial draft Version            |
 -- +========================================================================+

SET VERIFY    OFF;
SET TERM      OFF;
SET FEEDBACK  OFF;
SET SHOW      OFF;
SET ECHO      OFF; 
SET TAB       OFF; 


PROMPT
PROMPT Providing Grant on Custom Table to Apps......
PROMPT

WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Providing Grant on the Table XX_OM_SAS_HVOP_RECON to Apps .....
PROMPT

GRANT ALL ON XXOM.XX_OM_SAS_HVOP_RECON TO APPS;


WHENEVER SQLERROR EXIT 1

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;

