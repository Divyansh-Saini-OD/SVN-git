CREATE OR REPLACE VIEW XX_PA_PROJECTS_RPT_BFCST_V 
-- +===================================================================+
-- |                  Office Depot - PLM/PA-Project                    |
-- |              Private Brand China Global Sourcing                  |
-- +===================================================================+
-- | Name  :  XX_PA_PROJECTS_RPT_BFCST_V                               |
-- | Description: This View is Created for the PBCGS Reporting         |
-- |              for the PLM/PA team. Total Baseline Forecast         |
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
(       PROJECT_ID
       ,PROJECT_NUMBER
       ,PROJECT_NAME
       ,TOTAL_PROJECT_REVENUE
       ,TOTAL_RETAIL_SALES
       ,TOTAL_CONTRACT_SALES
       ,TOTAL_DIRECT_SALES
       ,TOTAL_BSD_SALES
       ,TOTAL_SALES )
AS
SELECT   PA.PROJECT_ID
        ,PA.SEGMENT1 
        ,PA.NAME 
        ,PBV.TOTAL_PROJECT_REVENUE
        ,SUM ( CASE PRA.EXPENDITURE_TYPE WHEN 'Retail Forecast'
            THEN (PBL.REVENUE) ELSE 0 END) AS RETAIL_SALES
        ,SUM ( CASE PRA.EXPENDITURE_TYPE WHEN 'Contract Forecast'
            THEN (PBL.REVENUE) ELSE 0 END) AS CONTRACT_SALES
        ,SUM ( CASE PRA.EXPENDITURE_TYPE WHEN 'Direct Forecast'
            THEN (PBL.REVENUE) ELSE 0 END) AS DIRECT_SALES
        ,SUM ( CASE PRA.EXPENDITURE_TYPE WHEN 'Contract Forecast'
            THEN (PBL.REVENUE) ELSE 0 END) +
         SUM ( CASE PRA.EXPENDITURE_TYPE WHEN 'Direct Forecast'
             THEN (PBL.REVENUE) ELSE 0 END) AS BSD_SALES
        ,SUM ( CASE PRA.EXPENDITURE_TYPE WHEN 'Retail Forecast'
            THEN (PBL.REVENUE) ELSE 0 END) +
         SUM ( CASE PRA.EXPENDITURE_TYPE WHEN 'Contract Forecast'
            THEN (PBL.REVENUE) ELSE 0 END) +
         SUM ( CASE PRA.EXPENDITURE_TYPE WHEN 'Direct Forecast'
            THEN (PBL.REVENUE) ELSE 0 END) AS TOTAL_SALES 
  FROM   PA_PROJECTS_ALL PA
        ,PA_BUDGET_VERSIONS PBV
        ,PA_RESOURCE_ASSIGNMENTS PRA
        ,PA_RESOURCE_LIST_MEMBERS RLM
        ,PA_BUDGET_LINES PBL
 WHERE   PA.PROJECT_ID = PBV.PROJECT_ID
   AND   PBV.BUDGET_VERSION_ID=PRA.BUDGET_VERSION_ID
   AND   PRA.RESOURCE_LIST_MEMBER_ID=RLM.RESOURCE_LIST_MEMBER_ID
   AND   PRA.RESOURCE_ASSIGNMENT_ID=PBL.RESOURCE_ASSIGNMENT_ID
   AND   PA.PROJECT_ID > 0
   AND   PBV.BUDGET_STATUS_CODE='B'
   AND   PBV.ORIGINAL_FLAG='Y'
   AND   PBV.CURRENT_ORIGINAL_FLAG='Y'
   GROUP BY PA.PROJECT_ID,PA.SEGMENT1,PA.NAME,PBV.TOTAL_PROJECT_REVENUE           
   ORDER BY PA.PROJECT_ID;
GRANT SELECT ON  XX_PA_PROJECTS_RPT_BFCST_V  TO EUL10_US;
/