SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +============================================================================================+
-- |                                     Office Depot                                           |
-- +============================================================================================+
-- | Name        : XX_SCM_BILL_SIGNAL_VW.vw                                                     |
-- | Description : Scripts to create Editioned Views and synonym for object XX_SCM_BILL_SIGNAL  |
-- | Rice Name: I3126                                                                           |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ===========     ================     ============================================|
-- | V1.0      09-OCT-2018     Havish Kasina        Initial version               				|
-- +============================================================================================+

PROMPT
PROMPT Creating Editioning View for XX_SCM_BILL_SIGNAL .....
PROMPT **Edition View creates as XX_SCM_BILL_SIGNAL# in XXFIN schema**
PROMPT **Synonym creates as XX_SCM_BILL_SIGNAL in apps schema**
PROMPT

exec ad_zd_table.upgrade('XXFIN', 'XX_SCM_BILL_SIGNAL'); 

SHOW ERRORS;
EXIT;