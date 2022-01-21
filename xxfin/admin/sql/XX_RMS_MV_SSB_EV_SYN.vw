SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +============================================================================================+
-- |                                     Office Depot                                           |
-- +============================================================================================+
-- | Name        : XX_RMS_MV_SSB_EV_SYN.vw                                                      |
-- | Description : Scripts to create Editioned Views  for object XX_RMS_MV_SSB                  |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ==========      ================     ============================================|
-- |1.0        25-MAR-2019     Punit Gupta          Initial version                             |
-- +============================================================================================+

PROMPT
PROMPT Creating Editioning View for XX_RMS_MV_SSB .....
PROMPT **Edition View creates as XX_RMS_MV_SSB# in XXFIN schema**
PROMPT **Synonym creates as XX_RMS_MV_SSB in apps schema**
PROMPT

exec ad_zd_table.upgrade('XXFIN','XX_RMS_MV_SSB');

SHOW ERRORS;
EXIT;