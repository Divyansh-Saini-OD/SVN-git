CREATE OR REPLACE VIEW XX_PA_PROJECTS_RPT_NEWSALES_V 
-- +===================================================================+
-- |                  Office Depot - PLM/PA-Project                    |
-- |              Private Brand China Global Sourcing                  |
-- +===================================================================+
-- | Name  :  XX_PA_PROJECTS_RPT_NEWSALES_V                           |
-- | Description: This View is Created for the PBCGS Reporting         |
-- |              for the PLM/PA team.  YEAR SALES BY NEW DATE         |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |                                                                   | 
-- |1.0      04-Oct-2007  Ian Bassaragh    Created The View            |
-- |             |                                                     |
-- +===================================================================+
(PROJECT_ID,
 START_DATE_FROM,
 START_DATE_TO,
 YEAR_END,
 YEARLY_SALES)
AS 
SELECT  PRA.PROJECT_ID,
        PBL.START_DATE,
        PBL.END_DATE,
        PPA2.END_DATE,
        SUM(PBL.REVENUE)
        FROM  PA_BUDGET_LINES PBL
             ,PA_RESOURCE_ASSIGNMENTS PRA
             ,PA_BUDGET_VERSIONS PBV
             ,XX_PA_PROJECTS_RPT_LAUNCHDT_V XL
             ,PA_PERIODS_ALL PPA
             ,PA_PERIODS_ALL PPA2
        WHERE PBL.RESOURCE_ASSIGNMENT_ID = PRA.RESOURCE_ASSIGNMENT_ID 
          AND PRA.BUDGET_VERSION_ID = PBV.BUDGET_VERSION_ID 
          AND PBV.BUDGET_STATUS_CODE='B'
          AND PBV.CURRENT_FLAG='Y'
          AND TRUNC(XL.CURRENT_LAUNCH_DATE) BETWEEN PPA.START_DATE AND PPA.END_DATE
          AND TRUNC(PBL.START_DATE) BETWEEN TRUNC(XL.CURRENT_LAUNCH_DATE) AND TRUNC(XL.CURRENT_LAUNCH_DATE + 900)
          AND TRUNC(PBL.END_DATE) <=
              (SELECT TRUNC(TO_DATE('1231'|| EXTRACT(YEAR FROM PPA.END_DATE), 'MM/DD/YYYY')) FROM DUAL )
          AND PPA2.GL_PERIOD_NAME like 'DEC%' 
          AND EXTRACT(YEAR FROM PPA2.END_DATE) = EXTRACT(YEAR FROM PPA.END_DATE)   
          AND PRA.PROJECT_ID = XL.PROJECT_ID
          AND PRA.PROJECT_ID > 0
     GROUP BY PRA.PROJECT_ID, PBL.START_DATE, PBL.END_DATE, PPA2.END_DATE
     ORDER BY PRA.PROJECT_ID;
GRANT SELECT ON  XX_PA_PROJECTS_RPT_NEWSALES_V TO EUL10_US;
/
