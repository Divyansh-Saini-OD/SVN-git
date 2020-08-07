SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +============================================================================================+
-- |                                     Office Depot                                           |
-- +============================================================================================+
-- | Name        : XX_AP_DROPSHIP_NON_DEDUCTIONS_VW.vw                                          |
-- | Description : Scripts to create Editioned Views and synonym for object XX_AP_DROPSHIP_NON_DEDUCTIONS |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ==========      ================     ============================================|
-- | V1.0     01-10-2018   	   Havish Kasina        Initial version               				|
-- +============================================================================================+

PROMPT
PROMPT Creating Editioning View for XX_AP_DROPSHIP_NON_DEDUCTIONS .....
PROMPT **Edition View creates as XX_AP_DROPSHIP_NON_DEDUCTIONS# in XXFIN schema**
PROMPT **Synonym creates as XX_AP_DROPSHIP_NON_DEDUCTIONS in apps schema**
PROMPT

exec ad_zd_table.upgrade('XXFIN', 'XX_AP_DROPSHIP_NON_DEDUCTIONS'); 

SHOW ERRORS;
EXIT;