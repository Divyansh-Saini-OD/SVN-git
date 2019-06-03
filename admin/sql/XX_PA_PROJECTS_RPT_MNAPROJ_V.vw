CREATE OR REPLACE VIEW XX_PA_PROJECTS_RPT_MNAPROJ_V 
-- +===================================================================+
-- |                  Office Depot - PLM/PA-Project                    |
-- |              Private Brand China Global Sourcing                  |
-- +===================================================================+
-- | Name  :  XX_PA_PROJECTS_RPT_MNAPROJ_V                             |
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
(  PROJECT_ID )
AS
SELECT PPA1.PROJECT_ID
    FROM   PA_TASKS PT
          ,PA_PROJECTS_ALL PPA1
          ,PA_PROJ_ELEMENTS PPE
          ,PA_PROJECT_STATUSES PPS
   WHERE   PPE.PROJECT_ID = PPA1.PROJECT_ID 
       AND PPE.PROJECT_ID = PT.PROJECT_ID 
       AND PPE.PROJ_ELEMENT_ID = PT.TASK_ID 
       AND PPE.ELEMENT_NUMBER = PT.TASK_NUMBER 
       AND PPA1.PROJECT_ID = PT.PROJECT_ID
       AND PT.TASK_NUMBER = '11' 
       AND PPA1.TEMPLATE_FLAG = 'N'
       AND PPA1.PROJECT_STATUS_CODE NOT IN ('CANCELLED', 'CLOSED', 'REJECTED')
       AND PPA1.SEGMENT1 LIKE 'PB%' 
       AND PPE.STATUS_CODE = PPS.PROJECT_STATUS_CODE
       AND PPS.PROJECT_SYSTEM_STATUS_CODE IN ('IN_PROGRESS', 'ON_HOLD');
GRANT SELECT ON  XX_PA_PROJECTS_RPT_MNAPROJ_V  TO EUL10_US;
/