CREATE OR REPLACE VIEW XX_PA_PROJECTS_RPT_WKSUMMARY_V 
-- +===================================================================+
-- |                  Office Depot - PLM/PA-Project                    |
-- |              Private Brand China Global Sourcing                  |
-- +===================================================================+
-- | Name  :  XX_PA_PROJECTS_RPT_WKSUMMARY_V                           |
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
       ,SCH_START_DATE
       ,SCH_END_DATE
       ,DEPARTMENT
       ,CLASS
       ,BRAND
       ,PROJECT_PROGRESS_STATUS
       ,SKU_NUM
       ,DOMESTIC_IMPORT
       ,SOURCING_AGENT
       ,COUNTRY_OF_ORIGIN
       ,SUPPLIER
       ,SUPPLIER_CONTACT
       ,CONTACT_PHONE
       ,SUPPLIER_EMAIL
       ,TRACKER_TYPE
       ,TRACK_DATE
       ,SA_AUDIT_STATUS
       ,QA_AUDIT_STATUS
       ,PRODUCT_WARRANTY
       ,CUSTOMER_SERVICE_STATUS
       ,ABM
       ,ACTIVITY_DESCRIPTION
       ,INITIAL_LAUNCH_DATE 
       ,CURRENT_LAUNCH_DATE 
       ,TOTAL_SALES 
       ,TOTAL_RETAIL_SALES 
       ,TOTAL_BSD_SALES 
       ,TOTAL_CONTRACT_SALES 
       ,TOTAL_DIRECT_SALES 
       ,LAUNCH_YEAR_SALES 
       ,DELAY_IMPACT
       ,ISSUE_SUMMARY
       ,ISSUE_DESCRIPTION
       ,ISSUE_STATUS
       ,ISSUE_STATUS_OVERVIEW
       ,ISSUE_RESOLUTION )
AS
SELECT PPA1.PROJECT_ID  
       ,PPA1.SEGMENT1  
       ,PPA1.NAME  
       ,PPS1.PROJECT_STATUS_NAME 
       ,V2.PROJECT_TYPE  
       ,PPA1.SCHEDULED_START_DATE  
       ,PPA1.SCHEDULED_FINISH_DATE  
       ,COALESCE(EEB1.C_EXT_ATTR1,'')  
       ,COALESCE(EEB1.C_EXT_ATTR2,'')   
       ,COALESCE(EEB1.C_EXT_ATTR3,'')   
       ,COALESCE(EEB1.C_EXT_ATTR4,'')   
       ,COALESCE(EEB1.N_EXT_ATTR1,0)   
       ,COALESCE(EEB2.C_EXT_ATTR1,'')   
       ,COALESCE(EEB2.C_EXT_ATTR2,'')   
       ,COALESCE(EEB2.C_EXT_ATTR3,'')   
       ,COALESCE(EEB2.C_EXT_ATTR4,'')   
       ,COALESCE(EEB2.C_EXT_ATTR5,'')   
       ,COALESCE(EEB2.C_EXT_ATTR6,'')   
       ,COALESCE(EEB2.C_EXT_ATTR7,'')   
       ,COALESCE(EEB3.C_EXT_ATTR1,'')   
       ,COALESCE(EEB3.N_EXT_ATTR1,0)   
       ,COALESCE(EEB4.C_EXT_ATTR1,'')  
       ,COALESCE(EEB4.C_EXT_ATTR2,'')   
       ,COALESCE(EEB5.C_EXT_ATTR1,'')   
       ,COALESCE(EEB5.C_EXT_ATTR2,'')   
       ,COALESCE(PRT1.RESOURCE_SOURCE_NAME,'')  
       ,V2.ACTIVITY_DESCRIPTION
       ,NVL(V1.INITIAL_LAUNCH_DATE,NVL(EEB1.D_EXT_ATTR1,'')) 
       ,NVL(V1.CURRENT_LAUNCH_DATE,NVL(EEB1.D_EXT_ATTR2,NVL(EEB1.D_EXT_ATTR1,''))) 
       ,COALESCE(V3.TOTAL_SALES,0) 
       ,COALESCE(V3.TOTAL_RETAIL_SALES,0) 
       ,COALESCE(V3.TOTAL_BSD_SALES,0) 
       ,COALESCE(V3.TOTAL_CONTRACT_SALES,0) 
       ,COALESCE(V3.TOTAL_DIRECT_SALES,0) 
       ,COALESCE(V4.LAUNCH_YEAR_SALES,0) 
       ,V5.DELAY_IMPACT
       ,V6.SUMMARY
       ,V6.DESCRIPTION
       ,V6.STATUS_CODE
       ,V6.STATUS_OVERVIEW
       ,V6.RESOLUTION  
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
              ( PA_PROJECTS_ERP_EXT_B EEB3 JOIN 
                 EGO_FND_DSC_FLX_CTX_EXT FND3 ON 
                 EEB3.ATTR_GROUP_ID = FND3.ATTR_GROUP_ID AND
                 FND3.DESCRIPTIVE_FLEX_CONTEXT_CODE = 'RPB_TRACKER') ON
                 PPA3.PROJECT_ID = EEB3.PROJECT_ID,
            PA_PROJECTS_ALL PPA4 LEFT OUTER JOIN 
              ( PA_PROJECTS_ERP_EXT_B EEB4 JOIN 
                 EGO_FND_DSC_FLX_CTX_EXT FND4 ON 
                 EEB4.ATTR_GROUP_ID = FND4.ATTR_GROUP_ID AND
                 FND4.DESCRIPTIVE_FLEX_CONTEXT_CODE = 'PB_QUALITY') ON
                 PPA4.PROJECT_ID = EEB4.PROJECT_ID,
            PA_PROJECTS_ALL PPA5 LEFT OUTER JOIN 
              ( PA_PROJECTS_ERP_EXT_B EEB5 JOIN 
                 EGO_FND_DSC_FLX_CTX_EXT FND5 ON 
                 EEB5.ATTR_GROUP_ID = FND5.ATTR_GROUP_ID AND
                 FND5.DESCRIPTIVE_FLEX_CONTEXT_CODE = 'PB_CUSTOMER_SUPPORT') ON
                 PPA5.PROJECT_ID = EEB5.PROJECT_ID,
            PA_PROJECTS_ALL PPA6 LEFT OUTER JOIN 
                PA_PROJ_PARTIES_PROG_EDIT_V PRT1 ON 
                PPA6.PROJECT_ID = PRT1.PROJECT_ID AND PRT1.PROJECT_ROLE_NAME = 'Project Manager',
           PA_PROJECTS_ALL PPA7 LEFT OUTER JOIN 
                XX_PA_PROJECTS_RPT_LAUNCHDT_V V1 ON 
                PPA7.PROJECT_ID = V1.PROJECT_ID,      
           PA_PROJECTS_ALL PPA8 LEFT OUTER JOIN 
                XX_PA_PROJECTS_RPT_CFCST_V V3 ON 
                PPA8.PROJECT_ID = V3.PROJECT_ID, 
           PA_PROJECTS_ALL PPA9 LEFT OUTER JOIN 
                XX_PA_PROJECTS_RPT_LAUNCHYS_V V4 ON 
                PPA9.PROJECT_ID = V4.PROJECT_ID,     
           PA_PROJECTS_ALL PPA0 LEFT OUTER JOIN 
                XX_PA_PROJECTS_RPT_ISSUES_V V6 ON 
                PPA0.PROJECT_ID = V6.PROJECT_ID AND V6.STATUS_CODE <> 'CI_CLOSED',	
           XX_PA_PROJECTS_RPT_ACTIVITY_V V2,
           XX_PA_PROJECTS_RPT_IMPACT_V V5           
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
         AND PPA1.PROJECT_ID = PPA8.PROJECT_ID 
         AND PPA1.PROJECT_ID = PPA9.PROJECT_ID 
         AND PPA1.PROJECT_ID = PPA0.PROJECT_ID
         AND PPA1.PROJECT_ID = V2.PROJECT_ID
         AND PPA1.PROJECT_ID = V5.PROJECT_ID 
       ORDER BY PPA1.PROJECT_ID;
GRANT SELECT ON  XX_PA_PROJECTS_RPT_WKSUMMARY_V  TO EUL10_US;
/