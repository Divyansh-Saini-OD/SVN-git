SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +============================================================================================+
-- |                                     Office Depot                                           |
-- +============================================================================================+
-- | Name        : XX_FIN_TRANSLATEVALUES_UPD.tbl                                               |
-- | Description : For Defects# 38962                                                    |
-- | Rice Id     : I2186                                                                        |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ==========      ================     ============================================|
-- |1.0        21-MAR-2017     Thilak Kumar E (CG)  Initial version                             |
-- +============================================================================================+

PROMPT
PROMPT Update the Table XX_FIN_TRANSLATEVALUES .....
PROMPT

UPDATE XX_FIN_TRANSLATEVALUES SET TARGET_VALUE25 = 'N' 
 WHERE TRANSLATE_ID = 18320 AND TARGET_VALUE25 IS NULL;

PROMPT
PROMPT Updating the data in Table XX_FIN_TRANSLATEVALUES is done.
PROMPT

SHOW ERRORS;
EXIT;