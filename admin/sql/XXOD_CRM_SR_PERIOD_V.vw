CREATE OR REPLACE VIEW XXOD_CRM_SR_PERIOD_V (PERIOD
                                             ,PERIOD_TYPE
                                             ,PERIOD_ORDER_BY
                                             )
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name         : XXOD_CRM_SR_PERIOD_V                               |
-- | Rice ID      : CTR Reports                                        |
-- | Description  : This view is used by XXOD_SR_FROM_PERIOD and       |
-- |                XXOD_SR_TO_PERIOD value sets to fetch the period   |
-- |                in RRRR, MON-RR and Week format.                   |
-- |Change Record :                                                    |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A  23-OCT-2007 Gokila T         Initial draft version       |
-- |      1.0 02-JUL-2008 Senthil Kumar    Modified for defect# 8489   | 
-- |                                                                   |
-- +===================================================================+
AS 
SELECT Period
      ,period_type
      ,DECODE(period_type
              ,'Yearly',Period
              ,'Monthly',TO_CHAR(TO_DATE('01-'||Period,'DD-MON-RR'),'RRRR-MM')
               ,'Weekly', DECODE(SUBSTR(period,5,1),1,TO_CHAR(TO_DATE('01-'||substr(period,7,6),'DD-MON-RR'),'RRRR-MM-DD'),
                                             2,TO_CHAR(TO_DATE('08-'||substr(period,7,6),'DD-MON-RR'),'RRRR-MM-DD'),
                                             3,TO_CHAR(TO_DATE('15-'||substr(period,7,6),'DD-MON-RR'),'RRRR-MM-DD'),
                                             4,TO_CHAR(TO_DATE('22-'||substr(period,7,6),'DD-MON-RR'),'RRRR-MM-DD'),
                                             TO_CHAR(TO_DATE('29-'||substr(period,7,6),'DD-MON-RR'),'RRRR-MM-DD'))
                              )
              PERIOD_ORDER_BY
FROM(
     SELECT Period
            ,'Yearly' PERIOD_TYPE
     FROM (
           SELECT DISTINCT TO_CHAR(calendar_date,'RRRR')PERIOD
           FROM bom_calendar_dates
           ORDER BY 1
           )
     UNION ALL
     SELECT Period
            ,'Monthly' PERIOD_TYPE
     FROM (
           SELECT DISTINCT TO_CHAR(calendar_date,'MON-RR') PERIOD
           FROM bom_calendar_dates
           ) 
    UNION ALL
     SELECT period
            ,'Weekly' PERIOD_TYPE
     FROM (SELECT DISTINCT 'Week'||TO_CHAR(calendar_date,'W')||' '|| TO_CHAR(calendar_date,'MON-RR') PERIOD
           FROM bom_calendar_dates
     )
     )
ORDER BY 3;
