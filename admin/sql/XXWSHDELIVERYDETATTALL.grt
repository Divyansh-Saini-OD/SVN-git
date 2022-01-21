-- +============================================================================================+
-- |                        Office Depot - Project Simplify                                     |
-- |                                                                                            |
-- +============================================================================================+
-- | Name         : XXWSHDELIVERYDETATTALL.grt                                               |
-- | Rice Id      : E1334_OM_Attributes_Setup                                                   | 
-- | Description  : OD Delivery Attributes                                                      |  
-- | Purpose      : Create Grant for Table XX_OM_DELIVERY_DETAILS_ATT_ALL                       |
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
PROMPT Providing Grant on object xx_wsh_delivery_det_att_all to Apps .....
PROMPT

GRANT ALL ON xxom.xx_wsh_delivery_det_att_all TO APPS
/

WHENEVER SQLERROR EXIT 1

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON
