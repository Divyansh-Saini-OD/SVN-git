CREATE OR REPLACE VIEW XX_PA_PROJECTS_RPT_MONTHSLS_V 
-- +===================================================================+
-- |                  Office Depot - PLM/PA-Project                    |
-- |              Private Brand China Global Sourcing                  |
-- +===================================================================+
-- | Name  :  XX_PA_PROJECTS_RPT_MONTHSLS_V                            |
-- | Description: This View is Created for the PBCGS Reporting         |
-- |              for the PLM/PA team.                                 |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |                                                                   | 
-- |1.0      26-Oct-2007  Ian Bassaragh    Created The View            |
-- |1.1      15-Apr-2010  Paddy Sanjeevi   Included all projects       |                                                     |
-- +===================================================================+
(       PROJECT_ID
       ,PROJECT_NUMBER
       ,CHANNEL
       ,BUDGET_YEAR
       ,MON1
       ,MON2
       ,MON3
       ,MON4
       ,MON5
       ,MON6
       ,MON7
       ,MON8
       ,MON9
       ,MON10
       ,MON11
       ,MON12
       ,SALES_TOTAL)
AS
SELECT  B.PROJECT_ID
       ,B.PROJECT_NUMBER
       ,B.EXPENDITURE_TYPE
       ,B.BUDGET_YEAR
       ,SUM(NVL(B.MON1,0)) AS MON1 
       ,SUM(NVL(B.MON2,0)) AS MON2 
       ,SUM(NVL(B.MON3,0)) AS MON3
       ,SUM(NVL(B.MON4,0)) AS MON4
       ,SUM(NVL(B.MON5,0)) AS MON5
       ,SUM(NVL(B.MON6,0)) AS MON6
       ,SUM(NVL(B.MON7,0)) AS MON7
       ,SUM(NVL(B.MON8,0)) AS MON8
       ,SUM(NVL(B.MON9,0)) AS MON9
       ,SUM(NVL(B.MON10,0)) AS MON10
       ,SUM(NVL(B.MON11,0)) AS MON11
       ,SUM(NVL(B.MON12,0)) AS MON12
       ,SUM(NVL(B.SALES_TOTAL,0)) AS SALES_TOTAL 
   FROM 
(SELECT 
       XD.PROJECT_ID
      ,PPA1.SEGMENT1 AS PROJECT_NUMBER
      ,NVL(E.EXPENDITURE_TYPE, 'Retail Forecast') AS EXPENDITURE_TYPE
      ,NVL(E.BUDGET_YEAR,EXTRACT(YEAR FROM XD.ALT_LAUNCH_DATE)) AS BUDGET_YEAR
      ,NVL(E.MON1,0) AS MON1 
      ,NVL(E.MON2,0) AS MON2 
      ,NVL(E.MON3,0) AS MON3
      ,NVL(E.MON4,0) AS MON4
      ,NVL(E.MON5,0) AS MON5
      ,NVL(E.MON6,0) AS MON6
      ,NVL(E.MON7,0) AS MON7
      ,NVL(E.MON8,0) AS MON8
      ,NVL(E.MON9,0) AS MON9
      ,NVL(E.MON10,0) AS MON10
      ,NVL(E.MON11,0) AS MON11
      ,NVL(E.MON12,0) AS MON12
      ,NVL(E.REVENUE,0) AS SALES_TOTAL
    FROM 
       PA_PROJECTS_ALL PPA1
      ,XX_PA_PROJECTS_RPT_ALTLNCHDT_V XD LEFT OUTER JOIN
       (SELECT PRA.PROJECT_ID
            ,PRA.EXPENDITURE_TYPE
            ,PBL.REVENUE
            ,PBL.START_DATE
            ,PBL.END_DATE
            ,EXTRACT(YEAR FROM PBL.END_DATE) AS BUDGET_YEAR
            ,EXTRACT(MONTH FROM END_DATE)
            ,CASE WHEN EXTRACT(MONTH FROM END_DATE) = 1
                    THEN PBL.REVENUE ELSE 0 END AS MON1
            ,CASE WHEN EXTRACT(MONTH FROM END_DATE) = 2
                    THEN PBL.REVENUE ELSE 0 END AS MON2
            ,CASE WHEN EXTRACT(MONTH FROM END_DATE) = 3
                    THEN PBL.REVENUE ELSE 0 END AS MON3
            ,CASE WHEN EXTRACT(MONTH FROM END_DATE) = 4
                    THEN PBL.REVENUE ELSE 0 END AS MON4
            ,CASE WHEN EXTRACT(MONTH FROM END_DATE) = 5
                    THEN PBL.REVENUE ELSE 0 END AS MON5
            ,CASE WHEN EXTRACT(MONTH FROM END_DATE) = 6
                    THEN PBL.REVENUE ELSE 0 END AS MON6
            ,CASE WHEN EXTRACT(MONTH FROM END_DATE) = 7
                    THEN PBL.REVENUE ELSE 0 END AS MON7
            ,CASE WHEN EXTRACT(MONTH FROM END_DATE) = 8
                    THEN PBL.REVENUE ELSE 0 END AS MON8
            ,CASE WHEN EXTRACT(MONTH FROM END_DATE) = 9
                    THEN PBL.REVENUE ELSE 0 END AS MON9
            ,CASE WHEN EXTRACT(MONTH FROM END_DATE) = 10
                    THEN PBL.REVENUE ELSE 0 END AS MON10
            ,CASE WHEN EXTRACT(MONTH FROM END_DATE) = 11
                    THEN PBL.REVENUE ELSE 0 END AS MON11
            ,CASE WHEN EXTRACT(MONTH FROM END_DATE) = 12
                    THEN PBL.REVENUE ELSE 0 END AS MON12
             FROM 
                  PA_BUDGET_LINES PBL
                 ,PA_RESOURCE_ASSIGNMENTS PRA
                 ,PA_BUDGET_VERSIONS PBV
                 ,APPS.XX_PA_PROJECTS_RPT_LAUNCHDT_V XL
            WHERE PBL.RESOURCE_ASSIGNMENT_ID = PRA.RESOURCE_ASSIGNMENT_ID 
                  AND PRA.BUDGET_VERSION_ID = PBV.BUDGET_VERSION_ID 
              AND PBV.BUDGET_STATUS_CODE='B'
              AND PBV.CURRENT_FLAG='Y'
              AND TRUNC(PBL.START_DATE) >=  TRUNC(XL.CURRENT_LAUNCH_DATE)
              AND PRA.PROJECT_ID = XL.PROJECT_ID
          AND PRA.PROJECT_ID > 0 
          ORDER BY PRA.PROJECT_ID ) E 
          ON XD.PROJECT_ID = E.PROJECT_ID  
         WHERE PPA1.PROJECT_ID > 0 
           AND PPA1.PROJECT_ID = XD.PROJECT_ID
--         AND PPA1.PROJECT_STATUS_CODE <> 'REJECTED'
           AND PPA1.TEMPLATE_FLAG = 'N'
           AND PPA1.SEGMENT1 LIKE 'PB%' ) B
         GROUP BY B.PROJECT_ID
                 ,B.PROJECT_NUMBER
                 ,B.EXPENDITURE_TYPE
                 ,B.BUDGET_YEAR
         ORDER BY B.PROJECT_ID
                 ,B.BUDGET_YEAR
                 ,B.EXPENDITURE_TYPE;
GRANT SELECT ON  XX_PA_PROJECTS_RPT_MONTHSLS_V  TO EUL10_US;
/
