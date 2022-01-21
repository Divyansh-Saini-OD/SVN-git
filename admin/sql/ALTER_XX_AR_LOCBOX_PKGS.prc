SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

PROMPT Altering PACKAGES XX_AR_LOCBOX_PKGS

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

-- +=======================================================================================+
-- |                  Office Depot - Project Simplify                                      |
-- +=======================================================================================+
-- | Name :ALTER_XX_AR_LOCBOX_PKGS.sql                                                    |
-- | Description : Recompiling lockbox packages for defect 14764                           |
-- |                                                                                       |
-- |                                                                                       |
-- |                                                                                       |
-- |                                                                                       |
-- |Change Record:                                                                         |
-- |===============                                                                        |
-- |Version   Date         Author               Remarks                                    |
-- |=======   ==========   =============        ===========================================|
-- | V1.0     31-OCT-11     Aravind A.          For Defect 14764                           |
-- |                                                                                       |
-- +=======================================================================================+ 

ALTER PACKAGE XX_AR_STD_LBX_SUB_PKG COMPILE BODY;

ALTER PACKAGE XX_AR_LOCKBOX_PROCESS_PKG COMPILE BODY;

ALTER PACKAGE XX_AR_STD_LBX_SUB_CHILD_PKG COMPILE BODY;

SHOW ERROR
