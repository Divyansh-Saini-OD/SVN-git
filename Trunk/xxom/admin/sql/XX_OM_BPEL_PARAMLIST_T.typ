-- +==========================================================================+
-- |                      Office Depot - Project Simplify                     |
-- |                    Oracle NAIO Consulting Organization                   |
-- +==========================================================================+
-- | Name        : XX_OM_BPEL_PARAMLIST_T                                     |
-- | Rice ID     : I0215_OrdtoPOS                                             |
-- | Description : Object Type Creation Script                                |
-- |               Common Database Object for BPEL Caller Utility             |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version  Date        Author                 Remarks                       |
-- |=======  ==========  ===================    ==============================|
-- |DRAFT 1A 10-Jul-2007 Vidhya Valantina T     Initial draft version         |
-- |1.0      10-Jul-2007 Vidhya Valantina T     Baselined after testing       |
-- |                                                                          |
-- +==========================================================================+

SET VERIFY      OFF
SET TERM        OFF
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

PROMPT
PROMPT Dropping Existing Object Type......
PROMPT

WHENEVER SQLERROR CONTINUE;

PPROMPT
PROMPT Dropping object type XX_OM_BPEL_PARAMLIST_T
PROMPT

DROP TYPE xx_om_bpel_paramlist_t;

WHENEVER SQLERROR EXIT 1

PROMPT
PROMPT Creating the Custom Object Type ......
PROMPT

CREATE TYPE xx_om_bpel_paramlist_t AS VARRAY(50) OF VARCHAR2(200);

/
WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;