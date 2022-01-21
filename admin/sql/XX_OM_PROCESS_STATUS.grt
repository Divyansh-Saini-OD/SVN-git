 -- +========================================================================+
   -- |                  Office Depot - Project Simplify                       |
   -- |                  Office Depot                                          |
   -- +========================================================================+
   -- | Name  :      XX_OM_PROCESS_STATUS.grt                                  |
   -- | Description:  This file  grants access to apps for custom table        |
   -- |               required for PAT reporting                               |
   -- |                                                                        |
   -- |Change Record:                                                          |
   -- |===============                                                         |
   -- |Version Date        Author           Remarks                            |
   -- |======= =========== ===============  ===================================|
   -- |1.0     11-MAY-2009 Matthew Craig    Initial draft Version              |
 -- +==========================================================================+

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
PROMPT Providing Grant on the Table XX_OM_PROCESS_STATUS to Apps .....
PROMPT

GRANT ALL ON XXOM.XX_OM_PROCESS_STATUS TO APPS;


WHENEVER SQLERROR EXIT 1

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;

