-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name         :DROP_XX_GI_VALIDATE_ITEM_T.typ                      |
-- | Rice ID      :E0341 Inventory Transfer                            |
-- | Description  :OD validate item type drop script.                  |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- | 1.0       06-Dec-2007 Arun Andavar     No previous version        |
-- +===================================================================+

SET VERIFY      OFF
SET TERM        OFF
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Dropping the Custom Table Type XX_GI_VALIDATE_ITEM_TAB_T ......
PROMPT

DROP TYPE XX_GI_VALIDATE_ITEM_TAB_T;

WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Dropping the Custom Type XX_GI_VALIDATE_ITEM_T......
PROMPT

DROP TYPE XX_GI_VALIDATE_ITEM_T;

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;