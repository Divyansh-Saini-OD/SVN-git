-- +============================================================================================+
-- |                        Office Depot - Project Simplify                                     |
-- |              Oracle NAIO/WIPRO/Office Depot/Consulting Organization                        |
-- +============================================================================================+
-- | Name         : XX_OM_OD_HOLD_ADD_INFO.grt                                                  |
-- | Rice Id      : E0244                                                                       | 
-- | Description  : OD HoldsManagementFrameworke Grant Creation                                 |  
-- | Purpose      : Providing grant on custom table and sequence.                               |
-- |                1. XX_OM_OD_HOLD_ADD_INFO (Additional Information Metadata Table)           |
-- |                2. XX_OM_OD_HOLD_ADD_INFO_S  (Sequence for Additional Information Table)    |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version    Date          Author           Remarks                                           | 
-- |=======    ==========    =============    ==================================================+
-- |DRAFT 1A   03-May-2007   Nabarun Ghosh    Initial Version                                   |
-- |1.1        04-JUN-2007   Nabarun Ghosh    Updated the Comments Section as per onsite        |
-- |                                          review                                            |
-- |1.2        23-JUL-2007   Nabarun Ghosh    Changed the Table Name, Inorder to accomodate the |
-- |                                          DFF/KFF's values                                  |
-- +============================================================================================+
SET VERIFY      OFF
SET TERM        OFF
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

PROMPT
PROMPT Providing Grant on Custom Tables to Apps......
PROMPT

WHENEVER SQLERROR CONTINUE

PROMPT
PROMPT Providing Grant on the Table XX_OM_OD_HOLD_ADD_INFO to Apps .....
PROMPT


GRANT ALL ON  XX_OM_OD_HOLD_ADD_INFO TO APPS;


WHENEVER SQLERROR CONTINUE

PROMPT
PROMPT Providing Grant on the Sequence XX_OM_OD_HOLD_ADD_INFO_S to Apps .....
PROMPT


GRANT ALL ON  XX_OM_OD_HOLD_ADD_INFO_S TO APPS;


WHENEVER SQLERROR CONTINUE

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;