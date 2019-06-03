CREATE OR REPLACE VIEW XX_PA_PROJECTS_RPT_NEWPROJ_V 
-- +===================================================================+
-- |                  Office Depot - PLM/PA-Project                    |
-- |              Private Brand China Global Sourcing                  |
-- +===================================================================+
-- | Name  :  XX_PA_PROJECTS_RPT_NEWPROJ_V                             |
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
-- |1.0      08-Feb-2008  Ian Bassaragh    Add activity_decsription    |
-- |             |                                                     |
-- +===================================================================+
(       PROJECT_ID
       ,PROJECT_NUMBER
       ,PROJECT_NAME
       ,PROJECT_STATUS 
       ,PROJECT_TYPE
       ,ACTIVITY_DESCRIPTION
       ,SCH_START_DATE
       ,SCH_END_DATE
       ,DEPARTMENT
       ,CLASS
       ,PROJECT_PROGRESS_STATUS
       ,SKU_NUM
       ,IMUPERCENT
       ,ADLPERCENT
       ,TRACKER_TYPE
       ,INITIAL_LAUNCH_DATE 
       ,CURRENT_LAUNCH_DATE 
       ,TOTAL_SALES
       ,IMU
       ,PGM_ADLOAD
       ,IGM
       ,APPROVED_FLAG
       ,CREATION_DATE)
AS
SELECT  PPA1.PROJECT_ID  
       ,PPA1.SEGMENT1  
       ,PPA1.NAME  
       ,PPS1.PROJECT_STATUS_NAME 
       ,V2.PROJECT_TYPE
       ,V2.ACTIVITY_DESCRIPTION  
       ,PPA1.SCHEDULED_START_DATE  
       ,PPA1.SCHEDULED_FINISH_DATE  
       ,COALESCE(EEB1.C_EXT_ATTR1,'')  
       ,COALESCE(EEB1.C_EXT_ATTR2,'') 
       ,COALESCE(EEB1.C_EXT_ATTR4,'')  
       ,COALESCE(EEB1.N_EXT_ATTR1,0)
       ,COALESCE(EEB1.N_EXT_ATTR2,0) 
       ,COALESCE(EEB1.N_EXT_ATTR3,0) 
       ,COALESCE(EEB3.C_EXT_ATTR1,'') 
       ,NVL(V1.INITIAL_LAUNCH_DATE,NVL(EEB1.D_EXT_ATTR1,'')) 
       ,NVL(V1.CURRENT_LAUNCH_DATE,NVL(EEB1.D_EXT_ATTR2,NVL(EEB1.D_EXT_ATTR1,''))) 
       ,COALESCE(V3.TOTAL_SALES,0)
       ,(COALESCE(V3.TOTAL_SALES,0) * COALESCE(EEB1.N_EXT_ATTR2,0) / 100) AS IMU
       ,((COALESCE(V3.TOTAL_SALES,0) * COALESCE(EEB1.N_EXT_ATTR3,0) / 100)) AS PGM_ADLOAD
       ,((COALESCE(V3.TOTAL_SALES,0) * COALESCE(EEB1.N_EXT_ATTR2,0) / 100) + (COALESCE(V3.TOTAL_SALES,0) *  COALESCE(EEB1.N_EXT_ATTR3,0) / 100)) AS IGM
       ,(CASE   
            WHEN PPS1.PROJECT_STATUS_NAME = 'Closed'     THEN 'YES'
            WHEN PPS1.PROJECT_STATUS_NAME = 'Approved'   THEN 'YES'
	    WHEN PPS1.PROJECT_STATUS_NAME = 'Submitted'  THEN 'YES'
            WHEN PPS1.PROJECT_STATUS_NAME = 'Pending Close'  THEN 'YES'
            ELSE 'NO'
        END) AS APPROVED_FLAG
       ,PPA1.CREATION_DATE 
       FROM PA_PROJECT_STATUSES PPS1,
            PA_PROJECTS_ALL PPA1 LEFT OUTER JOIN 
              ( PA_PROJECTS_ERP_EXT_B EEB1 JOIN 
                 EGO_FND_DSC_FLX_CTX_EXT FND1 ON 
                 EEB1.ATTR_GROUP_ID = FND1.ATTR_GROUP_ID AND
                 FND1.DESCRIPTIVE_FLEX_CONTEXT_CODE = 'PB_GEN_INFO') ON
                 PPA1.PROJECT_ID = EEB1.PROJECT_ID,
            PA_PROJECTS_ALL PPA3 LEFT OUTER JOIN 
              ( PA_PROJECTS_ERP_EXT_B EEB3 JOIN 
                 EGO_FND_DSC_FLX_CTX_EXT FND3 ON 
                 EEB3.ATTR_GROUP_ID = FND3.ATTR_GROUP_ID AND
                 FND3.DESCRIPTIVE_FLEX_CONTEXT_CODE = 'RPB_TRACKER') ON
                 PPA3.PROJECT_ID = EEB3.PROJECT_ID,
            PA_PROJECTS_ALL PPA7 LEFT OUTER JOIN 
                XX_PA_PROJECTS_RPT_LAUNCHDT_V V1 ON 
                PPA7.PROJECT_ID = V1.PROJECT_ID,      
            PA_PROJECTS_ALL PPA8 LEFT OUTER JOIN 
                XX_PA_PROJECTS_RPT_CFCST_V V3 ON 
                PPA8.PROJECT_ID = V3.PROJECT_ID,
            XX_PA_PROJECTS_RPT_ACTIVITY_V V2 
       WHERE PPA1.PROJECT_ID > 0 
         AND PPA1.TEMPLATE_FLAG = 'N'
         AND PPA1.PROJECT_STATUS_CODE = PPS1.PROJECT_STATUS_CODE
         AND PPS1.PROJECT_STATUS_NAME NOT IN ('Cancelled', 'Closed', 'Rejected')
         AND PPA1.SEGMENT1 LIKE 'PB%'
         AND PPA1.PROJECT_ID = PPA3.PROJECT_ID
         AND PPA1.PROJECT_ID = PPA7.PROJECT_ID 
         AND PPA1.PROJECT_ID = PPA8.PROJECT_ID 
         AND PPA1.PROJECT_ID = V2.PROJECT_ID
       ORDER BY PPA1.PROJECT_ID;
GRANT SELECT ON  XX_PA_PROJECTS_RPT_NEWPROJ_V  TO EUL10_US;
/