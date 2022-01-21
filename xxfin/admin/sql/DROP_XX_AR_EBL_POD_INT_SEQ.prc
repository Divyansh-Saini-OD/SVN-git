SET VERIFY      OFF
SET TERM        OFF
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

-- +===========================================================================+
-- |                               Office Depot                                |
-- |                         
-- +===========================================================================+
-- | Name        : DROP_XX_AR_EBL_POD_INT_S.seq                                |
-- | Description :                                                             |
-- | File to create sequence for XX_AR_EBL_POD_INT table                       |
-- | Table: XX_AR_EBL_POD_INT.                                                 |
-- |                                                                           |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author        Remarks            	               |
-- |======== =========== ============= ========================================|
-- |DRAFT 1A 26-OCT-2018 Capgemini     Initial draft version                   |
-- |                                                                           |
-- +===========================================================================+

-- ----------------------------------------------------------------------------
-- Drop Custom Sequence XX_AR_EBL_POD_INT_S
-- ----------------------------------------------------------------------------

WHENEVER SQLERROR CONTINUE;

SET TERM ON
PROMPT
PROMPT Dropping the Sequence XX_AR_EBL_POD_INT_S 
PROMPT

DROP SEQUENCE XXFIN.XX_AR_EBL_POD_INT_S;

DROP SEQUENCE XXFIN.XX_AR_EBL_POD_ERRORS_S;
  
/
   
PROMPT
PROMPT Exiting....
PROMPT