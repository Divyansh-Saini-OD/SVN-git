CREATE OR REPLACE VIEW XX_PA_PROJECTS_RPT_ROLES_V 
-- +===================================================================+
-- |                  Office Depot - PLM/PA-Project                    |
-- |              Private Brand China Global Sourcing                  |
-- +===================================================================+
-- | Name  :  XX_PA_PROJECTS_RPT_ROLES_V                               |
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
        ,ABM
        ,BRAND_MANAGER
        ,OD_MERCHANT
        ,BD_DIRECTOR 
        ,OD_PB_DIRECTOR )
AS
SELECT  PPA1.PROJECT_ID  
       ,PPA1.SEGMENT1  
       ,PPA1.NAME  
       ,COALESCE(PRT1.RESOURCE_SOURCE_NAME,'UNASSIGNED')   
       ,COALESCE(PRT2.RESOURCE_SOURCE_NAME,'UNASSIGNED')  
       ,COALESCE(PRT3.RESOURCE_SOURCE_NAME,'UNASSIGNED')  
       ,COALESCE(PRT4.RESOURCE_SOURCE_NAME,'UNASSIGNED')  
       ,COALESCE(PRT5.RESOURCE_SOURCE_NAME,'UNASSIGNED')  
     FROM      
            PA_PROJECTS_ALL PPA1 LEFT OUTER JOIN 
                PA_PROJ_PARTIES_PROG_EDIT_V PRT1 ON 
                PPA1.PROJECT_ID = PRT1.PROJECT_ID AND PRT1.PROJECT_ROLE_NAME = 'Project Manager',
            PA_PROJECTS_ALL PPA2 LEFT OUTER JOIN 
                PA_PROJ_PARTIES_PROG_EDIT_V PRT2 ON 
                PPA2.PROJECT_ID = PRT2.PROJECT_ID AND PRT2.PROJECT_ROLE_NAME = 'Business Manager', 
            PA_PROJECTS_ALL PPA3 LEFT OUTER JOIN 
                PA_PROJ_PARTIES_PROG_EDIT_V PRT3 ON 
                PPA3.PROJECT_ID = PRT3.PROJECT_ID AND PRT3.PROJECT_ROLE_NAME = 'Merchant',
            PA_PROJECTS_ALL PPA4 LEFT OUTER JOIN 
                PA_PROJ_PARTIES_PROG_EDIT_V PRT4 ON 
                PPA4.PROJECT_ID = PRT4.PROJECT_ID AND PRT4.PROJECT_ROLE_NAME = 'Director Business Development', 
  	      PA_PROJECTS_ALL PPA5 LEFT OUTER JOIN 
                PA_PROJ_PARTIES_PROG_EDIT_V PRT5 ON 
                PPA5.PROJECT_ID = PRT5.PROJECT_ID AND PRT5.PROJECT_ROLE_NAME = 'OD PB Director' 
         WHERE PPA1.PROJECT_ID > 0 AND PPA1.TEMPLATE_FLAG = 'N' AND 
             PPA1.PROJECT_ID = PPA2.PROJECT_ID  AND
             PPA1.PROJECT_ID = PPA3.PROJECT_ID  AND
             PPA1.PROJECT_ID = PPA4.PROJECT_ID  AND
             PPA1.PROJECT_ID = PPA5.PROJECT_ID   
             ORDER BY PPA1.PROJECT_ID;  
GRANT SELECT ON  XX_PA_PROJECTS_RPT_ROLES_V TO EUL10_US;
/