SET DEFINE       OFF
SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

PROMPT Giving GRANT ON XX_CE_ORDT_SAS_ITM Table

PROMPT Program exits IF the grant IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

-- +=====================================================================================================+
-- |                                Office Depot - Project Simplify                                      |
-- |                                     Oracle AMS Support                                              |
-- +=====================================================================================================+
-- |  Name:  Script to give grants on table : XX_CE_ORDT_SAS_ITM (RICE ID : R1392)                       |
-- |                                                                                                     |
-- |  Description: Synonym for XX_CE_ORDT_SAS_ITM table.                                                 |
-- |                                                                                                     |
-- |  Change Record:                                                                                     |
-- +=====================================================================================================+
-- | Version     Date         Author               Remarks                                               |
-- | =========   ===========  ===================  ======================================================|
-- | 1.0         14-Nov-2013  Abdul Khan           Initial version - QC Defect # 25401                   |
-- +=====================================================================================================+


GRANT ALL ON XXFIN.XX_CE_ORDT_SAS_ITM TO APPS;

GRANT SELECT ON XXFIN.XX_CE_ORDT_SAS_ITM TO XX_FIN_SELECT_FINDEV_R;
   
SHOW ERROR