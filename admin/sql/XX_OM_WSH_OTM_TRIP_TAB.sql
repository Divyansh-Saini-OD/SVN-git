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
-- |DRAFT 1A 13-Apr-2007  Faiz                   Initial draft version         |
-- |1.0      20-Jun-2007  Pankaj Kapse           Made changes as per new       |
-- |                                             standard                      |
-- |                                                                           |
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

WHENEVER SQLERROR CONTINUE;

PPROMPT
PROMPT Dropping object type XX_OM_WSH_OTM_TRIP_TAB
PROMPT

DROP TYPE XX_OM_WSH_OTM_TRIP_TAB ;

WHENEVER SQLERROR EXIT 1

PROMPT
PROMPT Creating the Custom Table Type ......
PROMPT

PROMPT
PROMPT Creating the Table Types .....
PROMPT

CREATE OR REPLACE TYPE XX_OM_WSH_OTM_TRIP_TAB AS TABLE OF XX_OM_WSH_OTM_TRIP_OBJ;
/

WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;