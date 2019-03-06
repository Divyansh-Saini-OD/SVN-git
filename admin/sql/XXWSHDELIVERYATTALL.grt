-- +============================================================================================+
-- |                        Office Depot - Project Simplify                                     |
-- |                                                                                            |
-- +============================================================================================+
-- | Name         : XXWSHDELIVERYATTALL.grt                                                  |
-- | Rice Id      :                                                                             | 
-- | Description  : OD Delivery Attributes                                                      |  
-- | Purpose      : Create Grant for Table xx_wsh_delivery_att_all                               |
-- |                                                                                            |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version    Date          Author                Remarks                                      | 
-- |=======    ==========    =================    ==============================================+
-- |DRAFT 1A   12-Jul-2007   Milind Rane          Initial Version                               |
-- |DRAFT 1B   16-Jul-2007   Milind Rane          Ranamed to XX_WSH                             |
-- +============================================================================================+

SET VERIFY      OFF
SET TERM        ON
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF


WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Providing Grant on Custom Tables,object and Sequence to Apps......
PROMPT
 
PROMPT
PROMPT Providing Grant on object xx_wsh_delivery_att_all to Apps .....
PROMPT

GRANT ALL ON xxom.xx_wsh_delivery_att_all TO APPS
/

WHENEVER SQLERROR EXIT 1

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON
