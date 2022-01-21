create or replace PACKAGE XX_PA_MONTH_END_BALS_RPT_PKG AS

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:  XX_PA_EXPDT_MTHLY_ACT_RPT_PKG                                                      |
-- |  Description:  OD: PA Month End Balances Report                                            |
-- |                CR631/731 - R1169                                                           |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         07-Apr-2010  Joe Klein        Initial version                                  |
-- | 1.1         06-Aug-2012  Adithya   	   New procedure XX_MAIN_GRP_RPT for the new report |
-- | 										   OD PA Month End Balances Report—Grouped as per   |
-- |										   defect# 13846	                                | 
-- +============================================================================================+
 
-- +============================================================================================+
-- |  Name: XX_PA_MONTH_END_BALS_RPT_PKG.XX_MAIN_RPT                                            |
-- |  Description: This pkg.procedure will extract project data at a point in time, up to and   |
-- |  including a particular PA period.                                                         |
-- =============================================================================================|
  PROCEDURE XX_MAIN_RPT
  (errbuff OUT NOCOPY VARCHAR2,
   retcode OUT NOCOPY NUMBER,
   p_period IN VARCHAR2 DEFAULT NULL,
   p_task_type IN VARCHAR2 DEFAULT NULL,
   p_project_num_from IN VARCHAR2 DEFAULT NULL,
   p_project_num_to IN VARCHAR2 DEFAULT NULL,
   p_company IN VARCHAR2 DEFAULT NULL);
   
   --start modification by Adithya for defect#13846
   PROCEDURE XX_MAIN_GRP_RPT
    (errbuff OUT NOCOPY VARCHAR2,
   retcode OUT NOCOPY NUMBER,
   p_start_period IN VARCHAR2 DEFAULT NULL,
   p_end_period IN VARCHAR2 DEFAULT NULL,   
   p_capital_task IN VARCHAR2 DEFAULT 'Y',
   p_service_type IN VARCHAR2 DEFAULT NULL,
   p_project_num_from IN VARCHAR2 DEFAULT NULL,
   p_project_num_to IN VARCHAR2 DEFAULT NULL,
   p_company IN VARCHAR2 DEFAULT NULL);
   
   FUNCTION  XX_PRJ_TSK_MINOR(xx_project_id number,xx_task_id number) RETURN VARCHAR2;
   --End modification by Adithya for defect#13846

END XX_PA_MONTH_END_BALS_RPT_PKG;


/
