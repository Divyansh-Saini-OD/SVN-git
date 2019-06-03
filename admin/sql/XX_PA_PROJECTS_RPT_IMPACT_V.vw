CREATE OR REPLACE VIEW XX_PA_PROJECTS_RPT_IMPACT_V 
-- +===================================================================+
-- |                  Office Depot - PLM/PA-Project                    |
-- |              Private Brand China Global Sourcing                  |
-- +===================================================================+
-- | Name  :  XX_PA_PROJECTS_RPT_IMPACT_V                              |
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
        ,DELAY_IMPACT )
AS
SELECT A.PROJECT_ID
      ,(COALESCE(B.BASE_YEAR_SALES,0) - COALESCE(C.SHIFT_YEAR_SALES,0))
  FROM PA_PROJECTS_ALL A LEFT OUTER JOIN
      XX_PA_PROJECTS_RPT_BASESALES_V B ON A.PROJECT_ID = B.PROJECT_ID,
      PA_PROJECTS_ALL AA LEFT OUTER JOIN
      XX_PA_PROJECTS_RPT_SLIDSALE_V C ON AA.PROJECT_ID = C.PROJECT_ID
     WHERE A.PROJECT_ID > 0
       AND A.TEMPLATE_FLAG = 'N'
       AND A.PROJECT_ID = AA.PROJECT_ID  
  ORDER BY A.PROJECT_ID;    
GRANT SELECT ON  XX_PA_PROJECTS_RPT_IMPACT_V TO EUL10_US;
/