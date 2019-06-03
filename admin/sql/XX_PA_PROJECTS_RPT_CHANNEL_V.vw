CREATE OR REPLACE VIEW XX_PA_PROJECTS_RPT_CHANNEL_V 
-- +===================================================================+
-- |                  Office Depot - PLM/PA-Project                    |
-- |              Private Brand China Global Sourcing                  |
-- +===================================================================+
-- | Name  :  XX_PA_PROJECTS_RPT_CHANNEL_V                             |
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
-- |             |                                                     |
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
SELECT DISTINCT
    A.PROJECT_ID
   ,A.PROJECT_NUMBER
   ,'Retail' AS CHANNEL
   ,A.BUDGET_YEAR
   ,SUM(CASE A.CHANNEL WHEN 'Retail Forecast'
         THEN A.MON1 ELSE 0 END) AS MON1
   ,SUM(CASE A.CHANNEL WHEN 'Retail Forecast'
         THEN A.MON2 ELSE 0 END) AS MON2
   ,SUM(CASE A.CHANNEL WHEN 'Retail Forecast'
         THEN A.MON3 ELSE 0 END) AS MON3
   ,SUM(CASE A.CHANNEL WHEN 'Retail Forecast'
         THEN A.MON4 ELSE 0 END) AS MON4
   ,SUM(CASE A.CHANNEL WHEN 'Retail Forecast'
         THEN A.MON5 ELSE 0 END) AS MON5
   ,SUM(CASE A.CHANNEL WHEN 'Retail Forecast'
         THEN A.MON6 ELSE 0 END) AS MON6
   ,SUM(CASE A.CHANNEL WHEN 'Retail Forecast'
         THEN A.MON7 ELSE 0 END) AS MON7
   ,SUM(CASE A.CHANNEL WHEN 'Retail Forecast'
         THEN A.MON8 ELSE 0 END) AS MON8
   ,SUM(CASE A.CHANNEL WHEN 'Retail Forecast'
         THEN A.MON9 ELSE 0 END) AS MON9
   ,SUM(CASE A.CHANNEL WHEN 'Retail Forecast'
         THEN A.MON10 ELSE 0 END) AS MON10
   ,SUM(CASE A.CHANNEL WHEN 'Retail Forecast'
         THEN A.MON11 ELSE 0 END) AS MON11
   ,SUM(CASE A.CHANNEL WHEN 'Retail Forecast'
         THEN A.MON12 ELSE 0 END) AS MON12
   ,SUM(CASE A.CHANNEL WHEN 'Retail Forecast'
         THEN A.SALES_TOTAL ELSE 0 END) AS SALES_TOTAL
FROM XX_PA_PROJECTS_RPT_MONTHSLS_V A
  GROUP BY A.PROJECT_ID
          ,A.PROJECT_NUMBER
          ,A.BUDGET_YEAR
UNION
SELECT DISTINCT
    B.PROJECT_ID
   ,B.PROJECT_NUMBER
   ,'Contract' AS CHANNEL
   ,B.BUDGET_YEAR
   ,SUM(CASE B.CHANNEL WHEN 'Contract Forecast'
         THEN B.MON1 ELSE 0 END) AS MON1
   ,SUM(CASE B.CHANNEL WHEN 'Contract Forecast'
         THEN B.MON2 ELSE 0 END) AS MON2
   ,SUM(CASE B.CHANNEL WHEN 'Contract Forecast'
         THEN B.MON3 ELSE 0 END) AS MON3
   ,SUM(CASE B.CHANNEL WHEN 'Contract Forecast'
         THEN B.MON4 ELSE 0 END) AS MON4
   ,SUM(CASE B.CHANNEL WHEN 'Contract Forecast'
         THEN B.MON5 ELSE 0 END) AS MON5
   ,SUM(CASE B.CHANNEL WHEN 'Contract Forecast'
         THEN B.MON6 ELSE 0 END) AS MON6
   ,SUM(CASE B.CHANNEL WHEN 'Contract Forecast'
         THEN B.MON7 ELSE 0 END) AS MON7
   ,SUM(CASE B.CHANNEL WHEN 'Contract Forecast'
         THEN B.MON8 ELSE 0 END) AS MON8
   ,SUM(CASE B.CHANNEL WHEN 'Contract Forecast'
         THEN B.MON9 ELSE 0 END) AS MON9
   ,SUM(CASE B.CHANNEL WHEN 'Contract Forecast'
         THEN B.MON10 ELSE 0 END) AS MON10
   ,SUM(CASE B.CHANNEL WHEN 'Contract Forecast'
         THEN B.MON11 ELSE 0 END) AS MON11
   ,SUM(CASE B.CHANNEL WHEN 'Contract Forecast'
         THEN B.MON12 ELSE 0 END) AS MON12
   ,SUM(CASE B.CHANNEL WHEN 'Contract Forecast'
         THEN B.SALES_TOTAL ELSE 0 END) AS SALES_TOTAL
FROM XX_PA_PROJECTS_RPT_MONTHSLS_V B
GROUP BY B.PROJECT_ID
        ,B.PROJECT_NUMBER
        ,B.BUDGET_YEAR
UNION
SELECT DISTINCT
    C.PROJECT_ID
   ,C.PROJECT_NUMBER
   ,'Direct' AS CHANNEL
   ,C.BUDGET_YEAR
   ,SUM(CASE C.CHANNEL WHEN 'Direct Forecast'
         THEN C.MON1 ELSE 0 END) AS MON1
   ,SUM(CASE C.CHANNEL WHEN 'Direct Forecast'
         THEN C.MON2 ELSE 0 END) AS MON2
   ,SUM(CASE C.CHANNEL WHEN 'Direct Forecast'
         THEN C.MON3 ELSE 0 END) AS MON3
   ,SUM(CASE C.CHANNEL WHEN 'Direct Forecast'
         THEN C.MON4 ELSE 0 END) AS MON4
   ,SUM(CASE C.CHANNEL WHEN 'Direct Forecast'
         THEN C.MON5 ELSE 0 END) AS MON5
   ,SUM(CASE C.CHANNEL WHEN 'Direct Forecast'
         THEN C.MON6 ELSE 0 END) AS MON6
   ,SUM(CASE C.CHANNEL WHEN 'Direct Forecast'
         THEN C.MON7 ELSE 0 END) AS MON7
   ,SUM(CASE C.CHANNEL WHEN 'Direct Forecast'
         THEN C.MON8 ELSE 0 END) AS MON8
   ,SUM(CASE C.CHANNEL WHEN 'Direct Forecast'
         THEN C.MON9 ELSE 0 END) AS MON9
   ,SUM(CASE C.CHANNEL WHEN 'Direct Forecast'
         THEN C.MON10 ELSE 0 END) AS MON10
   ,SUM(CASE C.CHANNEL WHEN 'Direct Forecast'
         THEN C.MON11 ELSE 0 END) AS MON11
   ,SUM(CASE C.CHANNEL WHEN 'Direct Forecast'
         THEN C.MON12 ELSE 0 END) AS MON12
   ,SUM(CASE C.CHANNEL WHEN 'Direct Forecast'
         THEN C.SALES_TOTAL ELSE 0 END) AS SALES_TOTAL
FROM XX_PA_PROJECTS_RPT_MONTHSLS_V C
GROUP BY C.PROJECT_ID
        ,C.PROJECT_NUMBER
        ,C.BUDGET_YEAR;
GRANT SELECT ON  XX_PA_PROJECTS_RPT_CHANNEL_V  TO EUL10_US;
/
