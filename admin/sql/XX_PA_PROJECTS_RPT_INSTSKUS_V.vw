CREATE OR REPLACE VIEW XX_PA_PROJECTS_RPT_INSTSKUS_V 
-- +===================================================================+
-- |                  Office Depot - PLM/PA-Project                    |
-- |              Private Brand China Global Sourcing                  |
-- +===================================================================+
-- | Name  :  XX_PA_PROJECTS_RPT_INSTSKUS_V                            |
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
       ,SKU
       ,SKU_DESCRIPTION
       ,VPC
       ,ODPB_ITEM_ID 
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
       ,INITIAL_LAUNCH_DATE 
       ,CURRENT_LAUNCH_DATE 
       ,TOTAL_SALES 
       ,TOTAL_RETAIL_SALES 
       ,TOTAL_BSD_SALES 
       ,TOTAL_CONTRACT_SALES 
       ,TOTAL_DIRECT_SALES 
       ,LAUNCH_YEAR_SALES
       ,LAUNCH_RETAIL_SALES 
       ,LAUNCH_BSD_SALES 
       ,LAUNCH_CONTRACT_SALES 
       ,LAUNCH_DIRECT_SALES
        )
AS
SELECT PPA1.PROJECT_ID  
       ,PPA1.SEGMENT1 AS PROJECT_NUMBER
       ,PPA1.NAME  AS PROJECT_NAME
       ,PPS1.PROJECT_STATUS_NAME AS PROJECT_STATUS
       ,COALESCE(EEB3.C_EXT_ATTR6,'') AS SKU 
       ,COALESCE(EEB3.C_EXT_ATTR8,'') AS SKU_DESCRIPTION
       ,COALESCE(EEB3.C_EXT_ATTR9,'') AS VPC
       ,COALESCE(EEB3.C_EXT_ATTR10,'') AS ODPB_ITEM_ID 
       ,COALESCE(EEB1.C_EXT_ATTR1,'') AS DEPARTMENT 
       ,COALESCE(EEB1.C_EXT_ATTR2,'') AS CLASS   
       ,COALESCE(EEB1.C_EXT_ATTR3,'') AS BRAND   
       ,COALESCE(EEB1.C_EXT_ATTR4,'') AS PROGRESS_STATUS   
       ,COALESCE(EEB1.N_EXT_ATTR1,0) AS SKU_NUM   
       ,COALESCE(EEB2.C_EXT_ATTR1,'') AS DOMESTIC_IMPORT   
       ,COALESCE(EEB2.C_EXT_ATTR2,'') AS SOURCING_AGENT   
       ,COALESCE(EEB2.C_EXT_ATTR3,'') AS COUNTRY_OF_ORIGIN  
       ,COALESCE(EEB2.C_EXT_ATTR4,'') AS SUPPLIER  
       ,COALESCE(EEB2.C_EXT_ATTR5,'') AS SUPPLIER_CONTACT 
       ,NVL(V1.INITIAL_LAUNCH_DATE,NVL(EEB1.D_EXT_ATTR1,'')) AS INITIAL_LAUNCH_DATE 
       ,NVL(V1.CURRENT_LAUNCH_DATE,NVL(EEB1.D_EXT_ATTR2,NVL(EEB1.D_EXT_ATTR1,''))) AS CURRENT_LAUNCH 
       ,COALESCE(V3.TOTAL_SALES,0) AS TOTAL_SALES 
       ,COALESCE(V3.TOTAL_RETAIL_SALES,0) AS TOTAL_RETAIL_SALES 
       ,COALESCE(V3.TOTAL_BSD_SALES,0) AS TOTAL_BSD_SALES 
       ,COALESCE(V3.TOTAL_CONTRACT_SALES,0) AS TOTAL_CONTRACT_SALES 
       ,COALESCE(V3.TOTAL_DIRECT_SALES,0) AS TOTAL_DIRECT_SALES 
       ,COALESCE(V4.LAUNCH_YEAR_SALES,0) AS LAUNCH_YEAR_SALES
       ,COALESCE(V4.RETAIL_SALES,0) AS LAUNCH_RETAIL_SALES 
       ,COALESCE(V4.BSD_SALES,0) AS LAUNCH_BSD_SALES 
       ,COALESCE(V4.CONTRACT_SALES,0) AS LAUNCH_CONTRACT_SALES 
       ,COALESCE(V4.DIRECT_SALES,0) AS LAUNCH_DIRECT_SALES 
       FROM APPS.PA_PROJECT_STATUSES PPS1,
            APPS.PA_PROJECTS_ALL PPA1 LEFT OUTER JOIN 
              ( APPS.PA_PROJECTS_ERP_EXT_B EEB1 JOIN 
                 APPS.EGO_FND_DSC_FLX_CTX_EXT FND1 ON 
                 EEB1.ATTR_GROUP_ID = FND1.ATTR_GROUP_ID AND
                 FND1.DESCRIPTIVE_FLEX_CONTEXT_CODE = 'PB_GEN_INFO') ON
                 PPA1.PROJECT_ID = EEB1.PROJECT_ID,
            APPS.PA_PROJECTS_ALL PPA2 LEFT OUTER JOIN 
              ( APPS.PA_PROJECTS_ERP_EXT_B EEB2 JOIN 
                 APPS.EGO_FND_DSC_FLX_CTX_EXT FND2 ON 
                 EEB2.ATTR_GROUP_ID = FND2.ATTR_GROUP_ID AND
                 FND2.DESCRIPTIVE_FLEX_CONTEXT_CODE = 'PB_SOURCING') ON
                 PPA2.PROJECT_ID = EEB2.PROJECT_ID,
            APPS.PA_PROJECTS_ALL PPA3 LEFT OUTER JOIN 
              ( APPS.PA_PROJECTS_ERP_EXT_B EEB3 JOIN 
                 APPS.EGO_FND_DSC_FLX_CTX_EXT FND3 ON 
                 EEB3.ATTR_GROUP_ID = FND3.ATTR_GROUP_ID AND
                 FND3.DESCRIPTIVE_FLEX_CONTEXT_CODE = 'QA') ON
                 PPA3.PROJECT_ID = EEB3.PROJECT_ID,
            APPS.PA_PROJECTS_ALL PPA7 LEFT OUTER JOIN 
                APPS.XX_PA_PROJECTS_RPT_LAUNCHDT_V V1 ON 
                PPA7.PROJECT_ID = V1.PROJECT_ID,      
           APPS.PA_PROJECTS_ALL PPA8 LEFT OUTER JOIN 
                APPS.XX_PA_PROJECTS_RPT_CFCST_V V3 ON 
                PPA8.PROJECT_ID = V3.PROJECT_ID, 
           APPS.PA_PROJECTS_ALL PPA9 LEFT OUTER JOIN 
                APPS.XX_PA_PROJECTS_RPT_LAUNCHYCS_V V4 ON 
                PPA9.PROJECT_ID = V4.PROJECT_ID     
       WHERE PPA1.PROJECT_ID > 0 
         AND PPA1.TEMPLATE_FLAG = 'N'
         AND PPA1.PROJECT_STATUS_CODE = PPS1.PROJECT_STATUS_CODE
         AND PPS1.PROJECT_STATUS_NAME NOT IN ('Cancelled', 'Rejected')
         AND PPA1.SEGMENT1 LIKE 'PB%'
         AND PPA1.PROJECT_ID = PPA2.PROJECT_ID
         AND PPA1.PROJECT_ID = PPA3.PROJECT_ID
         AND PPA1.PROJECT_ID = PPA7.PROJECT_ID 
         AND PPA1.PROJECT_ID = PPA8.PROJECT_ID 
         AND PPA1.PROJECT_ID = PPA9.PROJECT_ID 
    ORDER BY PPA1.PROJECT_ID;
GRANT SELECT ON XX_PA_PROJECTS_RPT_INSTSKUS_V TO EUL10_US;
/