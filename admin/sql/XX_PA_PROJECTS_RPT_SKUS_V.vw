CREATE OR REPLACE VIEW XX_PA_PROJECTS_RPT_SKUS_V 
-- +===================================================================+
-- |                  Office Depot - PLM/PA-Project                    |
-- |              Private Brand China Global Sourcing                  |
-- +===================================================================+
-- | Name  :  XX_PA_PROJECTS_RPT_SKUS_V                               |
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
(        PROJECT_ID
        ,PROJECT_NUMBER
        ,PROJECT_NAME
        ,PROJECT_STATUS 
        ,PROJECT_TYPE
        ,SCH_START_DATE
        ,SCH_END_DATE
        ,SKU
        ,SKU_DESCRIPTION )
AS
SELECT  PPA1.PROJECT_ID  
       ,PPA1.SEGMENT1  
       ,PPA1.NAME AS  
       ,PPA1.PROJECT_STATUS_CODE  
       ,PPA1.PROJECT_TYPE  
       ,PPA1.SCHEDULED_START_DATE  
       ,PPA1.SCHEDULED_FINISH_DATE  
       ,EEB1.C_EXT_ATTR6 
       ,EEB1.C_EXT_ATTR8 
        FROM 
        PA_PROJECTS_ALL PPA1 LEFT OUTER JOIN 
          ( PA_PROJECTS_ERP_EXT_B EEB1 JOIN 
            EGO_FND_DSC_FLX_CTX_EXT FND1 ON 
            EEB1.ATTR_GROUP_ID = FND1.ATTR_GROUP_ID AND
            FND1.DESCRIPTIVE_FLEX_CONTEXT_CODE = 'QA') ON
            PPA1.PROJECT_ID = EEB1.PROJECT_ID
      WHERE PPA1.PROJECT_ID > 0 AND PPA1.TEMPLATE_FLAG = 'N'  
        AND PPA1.SEGMENT1 LIKE 'PB%'  
        AND PPA1.PROJECT_ID = PPA1.PROJECT_ID  
      ORDER BY PPA1.PROJECT_ID;
GRANT SELECT ON  XX_PA_PROJECTS_RPT_SKUS_V TO EUL10_US;
/