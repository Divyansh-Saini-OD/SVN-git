SET VERIFY      OFF
SET TERM        OFF
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

-- +==========================================================================+
-- |                      Office Depot - Project Simplify                     |
-- |                    Oracle NAIO Consulting Organization                   |
-- +==========================================================================+
-- | Name        : DROP_XX_HZ_CUST_PROFILE_AMTS_AIUR1                              |
-- | Rice ID     : E0266_RoleRestrictionsMerges                               |
-- | Description : Custom Package called from the Workflow Engine. Contains a |
-- |               procedure Set_Notification that is called to determine the |
-- |               attributes for the Performer and the Message Details.      |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version  Date        Author                 Remarks                       |
-- |=======  ==========  ===================    ==============================|
-- |Draft 1a 30-Aug-2007 Vidhya Valantina T                                   |
-- |1.0      XX-Aug-2007 Vidhya Valantina T     Baselined after review        |
-- |                                                                          |
-- +==========================================================================+

SET TERM ON

WHENEVER SQLERROR EXIT 1;

PROMPT
PROMPT Drop Trigger XX_HZ_CUST_PROFILE_AMTS_AIUR1
PROMPT

DROP TRIGGER xx_hz_cust_profile_amts_aiur1;
/

SHOW ERRORS;

WHENEVER SQLERROR EXIT 1;

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;