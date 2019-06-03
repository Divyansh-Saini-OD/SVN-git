CREATE OR REPLACE VIEW XX_PA_PROJECTS_RPT_LIST_V 
-- +===================================================================+
-- |                  Office Depot - PLM/PA-Project                    |
-- |              Private Brand China Global Sourcing                  |
-- +===================================================================+
-- | Name  :  XX_PA_PROJECTS_RPT_LIST_V                                |
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
       ,ABM )
 AS
 SELECT PPA1.PROJECT_ID  
       ,PPA1.SEGMENT1  
       ,PPA1.NAME  
       ,PPA1.PROJECT_STATUS_CODE   
       ,PPA1.PROJECT_TYPE  
       ,PPA1.SCHEDULED_START_DATE  
       ,PPA1.SCHEDULED_FINISH_DATE  
       ,EEB1.C_EXT_ATTR1  
       ,EEB1.C_EXT_ATTR2  
       ,EEB1.C_EXT_ATTR3  
       ,EEB1.C_EXT_ATTR4  
       ,EEB1.N_EXT_ATTR1  
       ,EEB2.C_EXT_ATTR1  
       ,EEB2.C_EXT_ATTR2  
       ,EEB2.C_EXT_ATTR3  
       ,EEB2.C_EXT_ATTR4  
       ,EEB2.C_EXT_ATTR5  
       ,EEB2.C_EXT_ATTR6  
       ,EEB2.C_EXT_ATTR7  
       ,EEB3.C_EXT_ATTR1  
       ,EEB3.N_EXT_ATTR1  
       ,EEB4.C_EXT_ATTR1  
       ,EEB4.C_EXT_ATTR2  
       ,EEB5.C_EXT_ATTR1  
       ,EEB5.C_EXT_ATTR2  
       ,PRT1.RESOURCE_SOURCE_NAME  
       FROM PA_PROJECTS_ALL PPA1 LEFT OUTER JOIN 
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
                PPA6.PROJECT_ID = PRT1.PROJECT_ID AND PRT1.PROJECT_ROLE_NAME = 'Project Manager'
     WHERE PPA1.PROJECT_ID > 0 
	 AND PPA1.TEMPLATE_FLAG = 'N'
         AND PPA1.PROJECT_ID = PPA2.PROJECT_ID
         AND PPA1.PROJECT_ID = PPA3.PROJECT_ID
         AND PPA1.PROJECT_ID = PPA4.PROJECT_ID
         AND PPA1.PROJECT_ID = PPA5.PROJECT_ID
         AND PPA1.PROJECT_ID = PPA6.PROJECT_ID  
       ORDER BY PPA1.PROJECT_ID;
GRANT SELECT ON  XX_PA_PROJECTS_RPT_LIST_V  TO EUL10_US;
/
