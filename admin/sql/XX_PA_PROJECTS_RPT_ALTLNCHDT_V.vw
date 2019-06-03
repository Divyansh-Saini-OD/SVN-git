CREATE OR REPLACE VIEW XX_PA_PROJECTS_RPT_ALTLNCHDT_V 
-- +===================================================================+
-- |                  Office Depot - PLM/PA-Project                    |
-- |              Private Brand China Global Sourcing                  |
-- +===================================================================+
-- | Name  :  XX_PA_PROJECTS_RPT_ALTLNCHDT_V                           |
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
(    PROJECT_ID
    ,ALT_LAUNCH_DATE )
 AS
 SELECT   PPA1.PROJECT_ID
     ,MAX(PPEVS.SCHEDULED_FINISH_DATE)
 FROM PA_PROJECTS_ALL PPA1,
      PA_PROJ_ELEM_VER_SCHEDULE PPEVS,
      PA_PROJ_ELEMENT_VERSIONS PPEV,
      PA_TASKS PT
 WHERE PT.TASK_ID = PPEV.PROJ_ELEMENT_ID 
   AND PPEV.ELEMENT_VERSION_ID = PPEVS.ELEMENT_VERSION_ID
   AND PT.LONG_TASK_NAME LIKE 'Confirm Product In-Store or CSC'
   AND PT.PROJECT_ID > 0 
   AND PT.PROJECT_ID = PPA1.PROJECT_ID
   AND PPA1.TEMPLATE_FLAG = 'N'
   AND PPA1.SEGMENT1 LIKE 'PB%' 
       GROUP BY PPA1.PROJECT_ID 
UNION
 SELECT PPA2.PROJECT_ID
       ,TRUNC(PPA2.CREATION_DATE)
  FROM  PA_PROJECTS_ALL PPA2
  WHERE PPA2.PROJECT_ID > 0 
    AND PPA2.TEMPLATE_FLAG = 'N'
    AND PPA2.SEGMENT1 LIKE 'PB%' 
    AND PPA2.PROJECT_ID NOT IN 
       (SELECT distinct PT.PROJECT_ID
      FROM PA_PROJECTS_ALL PPA1,
         PA_PROJ_ELEM_VER_SCHEDULE PPEVS,
         PA_PROJ_ELEMENT_VERSIONS PPEV,
         PA_TASKS PT
       WHERE PT.TASK_ID = PPEV.PROJ_ELEMENT_ID
             AND PPEV.ELEMENT_VERSION_ID = PPEVS.ELEMENT_VERSION_ID
   AND PT.LONG_TASK_NAME LIKE 'Confirm Product In-Store or CSC'
   AND PT.PROJECT_ID > 0 
   AND PT.PROJECT_ID = PPA1.PROJECT_ID
   AND PPA1.TEMPLATE_FLAG = 'N'
   AND PPA1.SEGMENT1 LIKE 'PB%');
GRANT SELECT ON  XX_PA_PROJECTS_RPT_ALTLNCHDT_V TO EUL10_US;
/
