-- +============================================================================================+
-- |                        Office Depot - Project Simplify                                     |
-- |                                  Wipro Technologies                                        |
-- +============================================================================================+
-- | Name         : XXOMHEADERATTRIBUTESALL.grt                                                 |
-- | Rice Id      : E1334_OM_Attributes_Setup                                                   | 
-- | Description  : Grant Script for Header attributes table                                    |  
-- | Purpose      : Providing grant on custom table.                                            |
-- |                1. XX_OM_HEADER_ATTRIBUTES_ALL (Additional Information attributes           |
-- |                                                for Order header Table)                     |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version    Date          Author           Remarks                                           | 
-- |=======    ==========    =============    ==================================================+
-- |DRAFT 1A   05-JUL-2007   Prajeesh         Initial Version                                   |
-- |                                                                                            |
-- +============================================================================================+
SET VERIFY      OFF
SET TERM        ON
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

PROMPT
PROMPT Providing Grant on Custom Tables to Apps......
PROMPT

WHENEVER SQLERROR CONTINUE

PROMPT
PROMPT Providing Grant on the Table XX_OM_HEADER_ATTRIBUTES_ALL to Apps .....
PROMPT


GRANT ALL ON  XXOM.XX_OM_HEADER_ATTRIBUTES_ALL TO APPS;


WHENEVER SQLERROR CONTINUE

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;