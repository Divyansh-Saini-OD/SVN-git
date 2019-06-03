CREATE OR REPLACE VIEW XX_PA_PROJECTS_RPT_LAUNCHDT_V 
-- +===================================================================+
-- |                  Office Depot - PLM/PA-Project                    |
-- |              Private Brand China Global Sourcing                  |
-- +===================================================================+
-- | Name  :  XX_PA_PROJECTS_RPT_LAUNCHDT_V                            |
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
        ,INITIAL_LAUNCH_DATE
        ,CURRENT_LAUNCH_DATE )
AS
 SELECT  A.PROJECT_ID
        ,A.INITIAL_LAUNCH_DATE
        ,MIN(PBL2.START_DATE) AS CURRENT_LAUNCH_DATE
   FROM  PA_BUDGET_VERSIONS PBV2
        ,PA_RESOURCE_ASSIGNMENTS PRA2
        ,PA_RESOURCE_LIST_MEMBERS RLM2
        ,PA_BUDGET_LINES PBL2
        ,(SELECT PA.PROJECT_ID,
           MIN(PBL.START_DATE) AS INITIAL_LAUNCH_DATE
  	FROM PA_PROJECTS_ALL PA
       	,PA_BUDGET_VERSIONS PBV
       	,PA_RESOURCE_ASSIGNMENTS PRA
       	,PA_RESOURCE_LIST_MEMBERS RLM
       	,PA_BUDGET_LINES PBL
  	 WHERE PA.PROJECT_ID = PBV.PROJECT_ID
     	   AND PBV.BUDGET_VERSION_ID=PRA.BUDGET_VERSION_ID
     	   AND PRA.RESOURCE_LIST_MEMBER_ID=RLM.RESOURCE_LIST_MEMBER_ID
           AND PRA.RESOURCE_ASSIGNMENT_ID=PBL.RESOURCE_ASSIGNMENT_ID
           AND PA.PROJECT_ID > 0
           AND PBV.BUDGET_STATUS_CODE='B'
           AND PBV.ORIGINAL_FLAG='Y'
           AND PBV.CURRENT_ORIGINAL_FLAG='Y'
      GROUP BY PA.PROJECT_ID
      ORDER BY PA.PROJECT_ID) A          
          WHERE A.PROJECT_ID = PBV2.PROJECT_ID
         AND PBV2.BUDGET_VERSION_ID=PRA2.BUDGET_VERSION_ID
         AND PRA2.RESOURCE_LIST_MEMBER_ID=RLM2.RESOURCE_LIST_MEMBER_ID
         AND PRA2.RESOURCE_ASSIGNMENT_ID=PBL2.RESOURCE_ASSIGNMENT_ID
         AND PBV2.BUDGET_STATUS_CODE='B'
         AND PBV2.CURRENT_FLAG='Y'
      GROUP BY A.PROJECT_ID,A.INITIAL_LAUNCH_DATE
      ORDER BY A.PROJECT_ID ;
GRANT SELECT ON  XX_PA_PROJECTS_RPT_LAUNCHDT_V TO EUL10_US;
/