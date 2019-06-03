CREATE OR REPLACE VIEW XX_PA_PROJECTS_RPT_CURRSALES_V 
-- +===================================================================+
-- |                  Office Depot - PLM/PA-Project                    |
-- |              Private Brand China Global Sourcing                  |
-- +===================================================================+
-- | Name  :  XX_PA_PROJECTS_RPT_CURRSALES_V                           |
-- | Description: This View is Created for the PBCGS Reporting         |
-- |              for the PLM/PA team.  LAUNCH YEAR SALES              |
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
(        PROJECT_ID
        ,LAUNCH_YEAR_SALES )
AS
SELECT  PRA.PROJECT_ID,
        SUM(PBL.REVENUE)
   FROM PA_BUDGET_LINES PBL
       ,PA_RESOURCE_ASSIGNMENTS PRA
       ,PA_BUDGET_VERSIONS PBV
       ,XX_PA_PROJECTS_RPT_LAUNCHDT_V XL
       ,PA_PERIODS_ALL PPA
  WHERE PBL.RESOURCE_ASSIGNMENT_ID = PRA.RESOURCE_ASSIGNMENT_ID 
    AND PRA.BUDGET_VERSION_ID = PBV.BUDGET_VERSION_ID 
    --AND PBV.VERSION_NAME = 'Forecast' 
    AND PBV.BUDGET_STATUS_CODE='B'
    AND PBV.CURRENT_FLAG='Y'
    AND TRUNC(XL.CURRENT_LAUNCH_DATE) BETWEEN PPA.START_DATE AND PPA.END_DATE
    AND TRUNC(PBL.START_DATE) >=  TRUNC(XL.CURRENT_LAUNCH_DATE)
    AND TRUNC(PBL.END_DATE) <=
    (SELECT TRUNC(TO_DATE('1231'|| EXTRACT(YEAR FROM PPA.END_DATE), 'MM/DD/YYYY')) FROM DUAL )      
    AND PRA.PROJECT_ID = XL.PROJECT_ID
    AND PRA.PROJECT_ID > 0
  GROUP BY PRA.PROJECT_ID
  ORDER BY PRA.PROJECT_ID; 
GRANT SELECT ON  XX_PA_PROJECTS_RPT_CURRSALES_V TO EUL10_US;
/