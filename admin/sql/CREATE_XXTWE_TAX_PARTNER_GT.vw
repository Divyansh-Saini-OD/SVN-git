SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +============================================================================================+
-- |                                     Office Depot                                           |
-- +============================================================================================+
-- | Name        : XXTWE_TAX_PARTNER_GT.vw                                            |
-- | Description : Scripts to create Editioned Views and synonym for object XXTWE_TAX_PARTNER_GT|
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ==========      ================     ============================================|
-- |DRAFT 1A   30-OCT-2017        M K Pramod Kumar   Initial draft version          		   		|
-- +============================================================================================+

PROMPT
PROMPT Creating Editioning View for XXTWE_TAX_PARTNER_GT .....
PROMPT **Edition View creates as XXTWE_TAX_PARTNER_GT# in XXFIN schema**
PROMPT **Synonym creates as XXTWE_TAX_PARTNER_GT in apps schema**
PROMPT

exec ad_zd_table.upgrade('XXFIN','XXTWE_TAX_PARTNER_GT');

SHOW ERRORS;
EXIT;