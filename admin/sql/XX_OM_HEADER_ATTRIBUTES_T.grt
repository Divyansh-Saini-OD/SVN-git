-- +============================================================================================+
-- |                        Office Depot - Project Simplify                                     |
-- |              Wipro Technologies                                                            |
-- +============================================================================================+
-- | Name         : XX_OM_HEADER_ATTRIBUTES_T.grt                                               |
-- | Rice Id      : E1334_OM_Attributes_Setup                                                   | 
-- | Description  : Grant Script for Line attributes Object type                                |  
-- | Purpose      : Providing grant on custom object type.                                      |
-- |                1. XX_OM_HEADER_ATTRIBUTES_T (Additional Information attributes             |
-- |                                                for Order line Table)                       |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version    Date          Author           Remarks                                           | 
-- |=======    ==========    =============    ==================================================+
-- |DRAFT 1A   05-JUL-2007   Prajeesh         Initial Version                                   |
-- |                                                                                            |
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
PROMPT Providing Grant on the Table XX_OM_HEADER_ATTRIBUTES_T to Apps .....
PROMPT


GRANT ALL ON  XX_OM_HEADER_ATTRIBUTES_T TO APPS;


WHENEVER SQLERROR CONTINUE

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;