create or replace
PACKAGE XX_PA_FA_MTHLY_ACT_RPT_PKG AS

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:  XX_PA_FA_MTHLY_ACT_RPT_PKG                                                         |
-- |  Description:  OD: PA Fixed Asset Monthly Activity Report                                  |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         07-Apr-2010  Joe Klein        Initial version                                  |
-- | 1.1         28-NOV-2012  Rohit Ranjan     Defect# 14694                                    |
-- +============================================================================================+

-- +============================================================================================+
-- |  Name: XX_PA_FA_MTHLY_ACT_RPT_PKG.XX_MAIN_RPT                                              |
-- |  Description: This pkg.procedure will extract project data that was sent from PA to FA     |
-- |  for a particular PA period range.                                                         |
-- =============================================================================================|
  PROCEDURE XX_MAIN_RPT
  (errbuff OUT NOCOPY VARCHAR2,
   retcode OUT NOCOPY NUMBER,
   p_period_from IN VARCHAR2 DEFAULT NULL,
   p_period_to IN VARCHAR2 DEFAULT NULL,
   p_capital_task     IN VARCHAR2 DEFAULT 'Y',  --Defect# 14694
   p_service_type     IN VARCHAR2 DEFAULT NULL, --Defect# 14694
 --p_task_type IN VARCHAR2 DEFAULT NULL,--Commented as per Defect# 14694
   p_project_num_from IN VARCHAR2 DEFAULT NULL,
   p_project_num_to IN VARCHAR2 DEFAULT NULL,
   p_company IN VARCHAR2 DEFAULT NULL);

END XX_PA_FA_MTHLY_ACT_RPT_PKG;


/