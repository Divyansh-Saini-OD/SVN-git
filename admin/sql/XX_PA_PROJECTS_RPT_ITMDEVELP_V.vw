CREATE OR REPLACE VIEW XX_PA_PROJECTS_RPT_ITMDEVELP_V 
-- +===================================================================+
-- |                  Office Depot - PLM/PA-Project                    |
-- |              Private Brand China Global Sourcing                  |
-- +===================================================================+
-- | Name  :  XX_PA_PROJECTS_RPT_ITMDEVELP_V                           |
-- | Description: This View is Created for the PBCGS Reporting         |
-- |              for the PLM/PA team.                                 |
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
(    
        PROJECT_STATUS 
       ,TYPE
       ,PROJECT_NUM
       ,SKU_COUNT
       ,TOTAL_SALES 
       ,LAUNCH_YEAR_SALES 
       ,DELAY_IMPACT )
AS
SELECT A.PROJECT_STATUS
      ,A.TYPE
      ,COUNT(*) AS PROJECT_NUM
      ,SUM(A.SKU_NUM) AS SKU_COUNT
      ,SUM(A.TOTAL_SALES) AS TOTAL_SALES
      ,SUM(A.LAUNCH_YEAR_SALES) AS LAUNCH_YEAR_SALES
      ,SUM(A.DELAY_IMPACT) AS DELAY_IMPACT
FROM
(SELECT   
       (CASE   
            WHEN PPS1.PROJECT_STATUS_NAME = 'Closed'     THEN 'COMPLETE'
            WHEN PPS1.PROJECT_STATUS_NAME = 'Unapproved' THEN 'CONCEPT'
            WHEN PPS1.PROJECT_STATUS_NAME = 'On Hold'    THEN 'CONCEPT'
            WHEN PPS1.PROJECT_STATUS_NAME = 'Cancelled'  THEN 'DEAD'
            WHEN EEB1.C_EXT_ATTR4 = 'ON_TARGET_GREEN'    THEN 'GREEN'
            WHEN EEB1.C_EXT_ATTR4 = 'LATE_RED'           THEN 'RED'
            WHEN EEB1.C_EXT_ATTR4 = 'AT_RISK_YELLOW'     THEN 'YELLOW'
            WHEN PPS1.PROJECT_STATUS_NAME = 'Approved'   THEN 'APPROVED'
            ELSE 'NOT CLASSIFIED'
        END) AS PROJECT_STATUS
       ,V2.ACTIVITY_DESCRIPTION AS TYPE
       ,COALESCE(EEB1.N_EXT_ATTR1,0) AS SKU_NUM 
       ,COALESCE(V3.TOTAL_SALES,0) AS TOTAL_SALES 
       ,COALESCE(V4.LAUNCH_YEAR_SALES,0) AS LAUNCH_YEAR_SALES 
       ,V5.DELAY_IMPACT AS DELAY_IMPACT
  FROM PA_PROJECT_STATUSES PPS1,
       PA_PROJECTS_ALL PPA1 LEFT OUTER JOIN 
          ( PA_PROJECTS_ERP_EXT_B EEB1 JOIN 
            EGO_FND_DSC_FLX_CTX_EXT FND1 ON 
            EEB1.ATTR_GROUP_ID = FND1.ATTR_GROUP_ID AND
            FND1.DESCRIPTIVE_FLEX_CONTEXT_CODE = 'PB_GEN_INFO') ON
            PPA1.PROJECT_ID = EEB1.PROJECT_ID,
       PA_PROJECTS_ALL PPA8 LEFT OUTER JOIN 
            XX_PA_PROJECTS_RPT_CFCST_V V3 ON 
            PPA8.PROJECT_ID = V3.PROJECT_ID, 
       PA_PROJECTS_ALL PPA9 LEFT OUTER JOIN 
            XX_PA_PROJECTS_RPT_LAUNCHYS_V V4 ON 
            PPA9.PROJECT_ID = V4.PROJECT_ID,     
            XX_PA_PROJECTS_RPT_ACTIVITY_V V2,
            XX_PA_PROJECTS_RPT_IMPACT_V V5           
     WHERE PPA1.PROJECT_ID > 0 
       AND PPA1.TEMPLATE_FLAG = 'N'
       AND PPA1.PROJECT_STATUS_CODE = PPS1.PROJECT_STATUS_CODE
       AND PPS1.PROJECT_STATUS_NAME <> 'Rejected'
       AND PPA1.SEGMENT1 LIKE 'PB%'
       AND PPA1.PROJECT_ID = PPA8.PROJECT_ID 
       AND PPA1.PROJECT_ID = PPA9.PROJECT_ID 
       AND PPA1.PROJECT_ID = V2.PROJECT_ID
       AND PPA1.PROJECT_ID = V5.PROJECT_ID 
     ORDER BY PPA1.PROJECT_ID) A
     GROUP BY A.PROJECT_STATUS
             ,A.TYPE
     ORDER BY A.PROJECT_STATUS, A.TYPE ; 
GRANT SELECT ON  XX_PA_PROJECTS_RPT_ITMDEVELP_V  TO EUL10_US;
/