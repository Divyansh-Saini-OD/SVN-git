SET VERIFY      OFF
SET TERM        OFF
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF


-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- | Name :XX_PO_VENDOR_ADD_AUD_V1                                               |
-- | Description :   SQL Script to create Grants for the table                |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version      Date           Author               Remarks                  |
-- |=======    ==========     =============        ===========================|
-- | DRAFT 1.0 09-FEB-2020     Bhargavi Ankolekar Initial draft version       |
-- |                                                                          |
-- +==========================================================================+

-
WHENEVER SQLERROR CONTINUE;

SET TERM OFF

SET TERM ON

GRANT SELECT ON XX_PO_VENDOR_ADD_AUD_V1 TO ERP_SYSTEM_TABLE_SELECT_ROLE;


PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

SHOW ERRORS;
EXIT;

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================
