create or replace PACKAGE XX_PA_EXPDT_MTHLY_ACT_RPT_PKG AS

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:  XX_PA_EXPDT_MTHLY_ACT_RPT_PKG                                                      |
-- |  Description:  OD: PA Expenditures Monthly Activity Report                                 |
-- |                CR631/731 - R1170                                                           |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         22-Jan-2010  Joe Klein        Initial version                                  |
-- | 1.1         30-jan-2013  Divya            Defect#14693
-- +============================================================================================+
 
-- +============================================================================================+
-- |  Name: XX_PA_EXPDT_MTHLY_ACT_RPT_PKG.XX_MAIN_RPT                                           |
-- |  Description: This pkg.procedure will extract project data that originated in AP for a     |
-- |  particular PA period range and write it to the concurrent program's output.               |
-- =============================================================================================|
  PROCEDURE XX_MAIN_RPT
  (errbuff OUT NOCOPY VARCHAR2,
   retcode OUT NOCOPY NUMBER,
   p_period_from IN VARCHAR2 DEFAULT NULL,
   p_period_to IN VARCHAR2 DEFAULT NULL,
   --Start modification by divya for defect#14693
   --p_task_type IN VARCHAR2 DEFAULT NULL,
   p_capital_task     IN VARCHAR2 DEFAULT 'Y',  
   p_service_type     IN VARCHAR2 DEFAULT NULL, 
   p_vendor           IN VARCHAR2 DEFAULT NULL, 
   --End modification by divya for defect#14693
   p_project_num_from IN VARCHAR2 DEFAULT NULL,
   p_project_num_to IN VARCHAR2 DEFAULT NULL,
   p_company IN VARCHAR2 DEFAULT NULL);
   --Start modification by Adithya for defect#14693
   FUNCTION  XX_PRJ_TSK_MINOR(xx_project_id number,xx_task_id number) RETURN VARCHAR2;
   --End modification by Adithya for defect#14693

END XX_PA_EXPDT_MTHLY_ACT_RPT_PKG;


/
