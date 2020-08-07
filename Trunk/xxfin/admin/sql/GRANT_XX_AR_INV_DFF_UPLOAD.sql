-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- +===========================================================================+
-- | Name :XXFIN.XX_AR_AOPS_EBS_ORD_CHK                                        |
-- | Description :   Script to grant on xx_ar_inv_dff_upload table	           |
-- |  Rice ID : E3058                                                          |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version      Date           Author                  Remarks                |
-- |=======    ==========     =============             ====================== |
-- |DRAFT 1.0 19-Jul-2013     Yamuna      		        Initial draft versio   |
-- |                                                    Defect#21945 	       |
-- +===========================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON
WHENEVER SQLERROR CONTINUE

--+=====================================================================+
--+               GRANT TABLE XXFIN.XX_OD_UPLOAD_EXCEL_CONFIG           +
--+=====================================================================+

GRANT SELECT ON xxfin.xx_ar_inv_dff_upload TO XXFIN_SELECT_GROUP;

SHOW ERROR