create or replace PACKAGE XX_AR_LBX_BAT_RPT_PKG AS

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:  XX_AR_LBX_BAT_RPT_PKG                                                              |
-- |  Description:  OD: AR Lockbox Batch Report                                                 |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         20-Apr-2010  Joe Klein        Initial version                                  |
-- +============================================================================================+

-- +============================================================================================+
-- |  Name: XX_AR_LBX_BAT_RPT_PKG.XX_MAIN_RPT                                                   |
-- |  Description: This pkg.procedure will extract Lockbox data for reporting.                  |
-- =============================================================================================|
  PROCEDURE XX_MAIN_RPT
  (errbuff OUT NOCOPY VARCHAR2,
   retcode OUT NOCOPY NUMBER,
   P_BANK_ACCT_NUM IN VARCHAR2 DEFAULT NULL,
   P_LOCKBOX_NUMBER IN VARCHAR2 DEFAULT NULL,
   P_GL_DATE_FROM IN VARCHAR2 DEFAULT NULL,
   P_GL_DATE_TO IN VARCHAR2 DEFAULT NULL,
   P_DEPOSIT_DATE_FROM IN VARCHAR2 DEFAULT NULL,
   P_DEPOSIT_DATE_TO IN VARCHAR2 DEFAULT NULL,
   P_BATCH_STATUS IN VARCHAR2 DEFAULT NULL);

END XX_AR_LBX_BAT_RPT_PKG;


/
