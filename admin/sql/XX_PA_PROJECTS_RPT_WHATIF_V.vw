CREATE OR REPLACE VIEW XX_PA_PROJECTS_RPT_WHATIF_V 
-- +===================================================================+
-- |                  Office Depot - PLM/PA-Project                    |
-- |              Private Brand China Global Sourcing                  |
-- +===================================================================+
-- | Name  :  XX_PA_PROJECTS_RPT_WHATIF_V                              |
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
(       PROJECT_ID
       ,PROJECT_NUMBER
       ,PROJECT_NAME
       ,PROJECT_STATUS 
       ,PROJECT_TYPE
       ,DEPARTMENT
       ,CLASS
       ,BRAND
       ,PROJECT_PROGRESS_STATUS
       ,SKU_NUM
       ,SUPPLIER
       ,ACTIVITY_DESCRIPTION
       ,INITIAL_LAUNCH_DATE 
       ,CURRENT_LAUNCH_DATE 
       ,LAUNCH_YEAR_SALES
       ,ABM
       ,OD_MERCHANT
       ,OD_PB_DIRECTOR
       ,PERIOD_START
       ,PERIOD_END
       ,YEAR_END
       ,PERIOD_SALES ) 
 AS
 SELECT
        A.PROJECT_ID
       ,A.PROJECT_NUMBER
       ,A.PROJECT_NAME
       ,A.PROJECT_STATUS 
       ,A.PROJECT_TYPE
       ,A.DEPARTMENT
       ,A.CLASS
       ,A.BRAND
       ,A.PROJECT_PROGRESS_STATUS
       ,A.SKU_NUM
       ,A.SUPPLIER
       ,A.ACTIVITY_DESCRIPTION
       ,A.INITIAL_LAUNCH_DATE 
       ,A.CURRENT_LAUNCH_DATE 
       ,A.LAUNCH_YEAR_SALES
       ,A.ABM
       ,A.OD_MERCHANT
       ,A.OD_PB_DIRECTOR 
       ,NVL(V9.START_DATE_FROM,'31-Dec-06')
       ,NVL(V9.START_DATE_TO,'31-Dec-06')
       ,NVL(V9.YEAR_END,'31-Dec-2999')
       ,NVL(V9.YEARLY_SALES,0) 
     FROM                                                  
 ( SELECT
        PPA1.PROJECT_ID  AS PROJECT_ID
       ,PPA1.SEGMENT1 AS PROJECT_NUMBER 
       ,PPA1.NAME  AS PROJECT_NAME
       ,PPS1.PROJECT_STATUS_NAME  AS PROJECT_STATUS 
       ,V2.PROJECT_TYPE  AS PROJECT_TYPE
       ,COALESCE(EEB1.C_EXT_ATTR1,'') AS DEPARTMENT 
       ,COALESCE(EEB1.C_EXT_ATTR2,'') AS CLASS  
       ,COALESCE(EEB1.C_EXT_ATTR3,'') AS BRAND   
       ,COALESCE(EEB1.C_EXT_ATTR4,'') AS PROJECT_PROGRESS_STATUS 
       ,COALESCE(EEB1.N_EXT_ATTR1,0) AS SKU_NUM
       ,COALESCE(EEB2.C_EXT_ATTR4,'') AS SUPPLIER   
       ,V2.ACTIVITY_DESCRIPTION AS ACTIVITY_DESCRIPTION
       ,NVL(V1.INITIAL_LAUNCH_DATE,NVL(EEB1.D_EXT_ATTR1,'')) AS INITIAL_LAUNCH_DATE
       ,NVL(V1.CURRENT_LAUNCH_DATE,NVL(EEB1.D_EXT_ATTR2,NVL(EEB1.D_EXT_ATTR1,''))) AS CURRENT_LAUNCH_DATE
       ,COALESCE(V4.LAUNCH_YEAR_SALES,0) AS LAUNCH_YEAR_SALES
       ,COALESCE(PRT1.RESOURCE_SOURCE_NAME,'')  AS ABM 
       ,COALESCE(PRT2.RESOURCE_SOURCE_NAME,'') AS OD_MERCHANT
       ,COALESCE(PRT3.RESOURCE_SOURCE_NAME,'') AS OD_PB_DIRECTOR  
      FROM PA_PROJECT_STATUSES PPS1,
           PA_PROJECTS_ALL PPA1 LEFT OUTER JOIN 
              ( PA_PROJECTS_ERP_EXT_B EEB1 JOIN 
                 EGO_FND_DSC_FLX_CTX_EXT FND1 ON 
                 EEB1.ATTR_GROUP_ID = FND1.ATTR_GROUP_ID AND
                 FND1.DESCRIPTIVE_FLEX_CONTEXT_CODE = 'PB_GEN_INFO') ON
                 PPA1.PROJECT_ID = EEB1.PROJECT_ID,
           PA_PROJECTS_ALL PPA2 LEFT OUTER JOIN 
              ( PA_PROJECTS_ERP_EXT_B EEB2 JOIN 
                 EGO_FND_DSC_FLX_CTX_EXT FND2 ON 
                 EEB2.ATTR_GROUP_ID = FND2.ATTR_GROUP_ID AND
                 FND2.DESCRIPTIVE_FLEX_CONTEXT_CODE = 'PB_SOURCING') ON
                 PPA2.PROJECT_ID = EEB2.PROJECT_ID,     
           PA_PROJECTS_ALL PPA3 LEFT OUTER JOIN 
                PA_PROJ_PARTIES_PROG_EDIT_V PRT1 ON 
                PPA3.PROJECT_ID = PRT1.PROJECT_ID AND PRT1.PROJECT_ROLE_NAME = 'Project Manager',
           PA_PROJECTS_ALL PPA4 LEFT OUTER JOIN 
                PA_PROJ_PARTIES_PROG_EDIT_V PRT2 ON 
                PPA4.PROJECT_ID = PRT2.PROJECT_ID AND PRT2.PROJECT_ROLE_NAME = 'Merchant',
           PA_PROJECTS_ALL PPA5 LEFT OUTER JOIN 
                PA_PROJ_PARTIES_PROG_EDIT_V PRT3 ON 
                PPA5.PROJECT_ID = PRT3.PROJECT_ID AND PRT3.PROJECT_ROLE_NAME = 'OD PB Director',   
           PA_PROJECTS_ALL PPA6 LEFT OUTER JOIN 
                XX_PA_PROJECTS_RPT_LAUNCHDT_V V1 ON 
                PPA6.PROJECT_ID = V1.PROJECT_ID,      
           PA_PROJECTS_ALL PPA7 LEFT OUTER JOIN 
                XX_PA_PROJECTS_RPT_LAUNCHYS_V V4 ON 
                PPA7.PROJECT_ID = V4.PROJECT_ID,     
           XX_PA_PROJECTS_RPT_ACTIVITY_V V2
       WHERE PPA1.PROJECT_ID > 0 
         AND PPA1.TEMPLATE_FLAG = 'N'
         AND PPA1.PROJECT_STATUS_CODE = PPS1.PROJECT_STATUS_CODE
         AND PPS1.PROJECT_STATUS_NAME NOT IN ('Cancelled', 'Closed', 'Rejected')
         AND PPA1.SEGMENT1 LIKE 'PB%' 
         AND PPA1.PROJECT_ID = PPA2.PROJECT_ID
         AND PPA1.PROJECT_ID = PPA3.PROJECT_ID
         AND PPA1.PROJECT_ID = PPA4.PROJECT_ID
         AND PPA1.PROJECT_ID = PPA5.PROJECT_ID
         AND PPA1.PROJECT_ID = PPA6.PROJECT_ID
         AND PPA1.PROJECT_ID = PPA7.PROJECT_ID 
         AND PPA1.PROJECT_ID = V2.PROJECT_ID
       ORDER BY PPA1.PROJECT_ID ) A
          LEFT OUTER JOIN 
                XX_PA_PROJECTS_RPT_NEWSALES_V V9 ON 
                A.PROJECT_ID = V9.PROJECT_ID ;
GRANT SELECT ON  XX_PA_PROJECTS_RPT_WHATIF_V  TO EUL10_US;
/
