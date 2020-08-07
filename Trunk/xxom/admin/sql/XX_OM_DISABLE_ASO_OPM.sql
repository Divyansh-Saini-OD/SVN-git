-- +===========================================================================+
-- |                      Office Depot - Project Simplify                      |
-- |                    Oracle NAIO Consulting Organization                    |
-- +===========================================================================+
-- | Name        : XX_OM_WSH_OTM_TRIP_TAB                                      |
-- | Rice ID     : E0280_CarrierSelection                                      |
-- | Description :                                                             |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version   Date        Author                 Remarks                       |
-- |=======   ==========  ===================    ==============================|
-- |1.0      11-Dec-2007  Manish Chavan          Set the installed status to N |
-- |                                             for ASO and OPM for performanc|
-- |                                             e improvement                 |
-- +===========================================================================+

SET VERIFY      OFF
SET TERM        OFF
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

PROMPT
PROMPT Dropping Existing Custom Table Type......
PROMPT

update FND_PRODUCT_INSTALLATIONS set status = 'N' where application_id = 697;
update FND_PRODUCT_INSTALLATIONS set status = 'N' where application_id = 550;

WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON
COMMIT;
EXIT;
