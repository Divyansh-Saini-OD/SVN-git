-- +============================================================================================+
-- |                        Office Depot - Project Simplify                                     |
-- |                                                                                            |
-- +============================================================================================+
-- | Name         : XXWSHDELIVERYDETATTALLT.grt                                                 |
-- | Rice Id      : E1334_OM_Attributes_Setup                                                   | 
-- | Description  : OD Delivery Details Attributes Type                                         |  
-- | Purpose      : Create Grant for Type xx_wsh_delivery_det_att_t                             |
-- |                                                                                            |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version    Date          Author                Remarks                                      | 
-- |=======    ==========    =================    ==============================================+
-- |DRAFT 1A   19-Jul-2007   Milind Rane          Initial Version                               |
-- +============================================================================================+

SET VERIFY      OFF
SET TERM        ON
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF


WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Providing Grant on Custom Type to Apps......
PROMPT
 
PROMPT
PROMPT Providing Grant on object xx_wsh_delivery_det_att_t to Apps .....
PROMPT

GRANT ALL ON xxom.xx_wsh_delivery_det_att_t TO APPS
/

WHENEVER SQLERROR EXIT 1

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON
